extends MarginContainer

signal limit_camera(left, right, top, bottom)

enum Focus {TOP, ONE_QUARTER, CENTER, THREE_QUARTERS, BOTTOM}
enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}

@export var background_resource: Background
	#set = set_background_resouce
@export var texture: CompressedTexture2D
@export var layers := 1
@export var layer_scales: Dictionary
@export var layer_height_offsets: Dictionary
@export var horizontal_speed: float = 0.0
@export var tile_mode: TileMode
@export var back_tile_mode: TileMode

var camera: Camera2D
var texture_rect_full_size = {}
var layer_base_offset = {} #vanishing_point, height_offset, tile_mode
var layer_animation_offset = {} #used for moving bgs
@onready var w = get_tree().get_root().get_node("World")
@onready var pb = w.get_node("ParallaxBackground")

#func set_background_resouce(value): #note this goes through inspector on_changed code
	#background_resource = value
	#print("set background resource")

func _ready():
	setup()

func setup():
	#Only setup after other thing in scene tree have already finished initialized
	await get_tree().process_frame
	camera = get_viewport().get_camera_2d()
	#This manual check happen because Juniper get deleted and respawned in 1 frame when changing scene
	#causing Godot to may fail to recognize the PlayerCamera.
	if (camera == null):
		var player_camera: Camera2D = w.get_node_or_null("Juniper/PlayerCamera")
		if (player_camera and player_camera.enabled):
			camera = player_camera
			camera.make_current()

	setup_background_resource()
	setup_layers()
	update_layers()

	#Wait for the entire tree done initializing to have a proper camera
	if camera:
		connect("limit_camera", Callable(camera, "on_limit_camera"))
		if camera.name == "EditorCamera":
			camera.connect("camera_zoom_changed", Callable(self, "on_camera_zoom_changed"))
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)

func _process(delta):
	var desired_fps = 60
	var variance = delta * desired_fps
	for layer in pb.get_children():
		var index = layer.get_index()
		if !texture_rect_full_size.has(index) || !layer_base_offset.has(index): return #if we haven't set this yet by calling update_layers

		if !layer_animation_offset.has(index): #first time setup
			layer_animation_offset[index] = Vector2.ZERO
		layer_animation_offset[index] += Vector2(horizontal_speed * variance * layer_scales[index].x, 0)
		var texture_width = layer.get_child(0).texture.get_width()
		if layer_animation_offset[index].x >= texture_width \
		or layer_animation_offset[index].x <= texture_width * -1.0:
			layer_animation_offset[index] = Vector2.ZERO #reset to start
		layer.motion_offset = layer_base_offset[index] + layer_animation_offset[index]

func setup_background_resource():
	#background_resource.texture.emit_changed()
	# TODO: This ignores overrides set directly on the LevelLimiter
	texture = background_resource.texture
	layers = background_resource.layers
	layer_scales = background_resource.layer_scales
	layer_height_offsets = background_resource.layer_height_offsets
	horizontal_speed = background_resource.horizontal_speed
	var tile_mode_index = background_resource.tile_mode
	tile_mode = TileMode[TileMode.find_key(tile_mode_index)]
	var back_tile_mode_index = background_resource.back_tile_mode
	back_tile_mode = TileMode[TileMode.find_key(back_tile_mode_index)]

func setup_layers():
	for c in pb.get_children():
		c.free()

	for layer_index in layers:
		var layer = ParallaxLayer.new()
		pb.add_child(layer)

		if layer_scales.has(layer_index): layer.motion_scale = layer_scales[layer_index]
		else: layer.motion_scale = Vector2.ZERO

		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_TILE
		texture_rect.mouse_filter = MOUSE_FILTER_IGNORE

		var layer_height = int(texture.get_height() / float(layers))
		var layer_y = layer_height * layer_index
		var region = Rect2i(0, layer_y, texture.get_width(), layer_height)

		#this cannot be AtlasTexture due to bug https://github.com/godotengine/godot/issues/20472
		var texture_as_image = texture.get_image()
		var clipped_image = texture_as_image.get_region(region)
		var clipped_texture = ImageTexture.create_from_image(clipped_image)

		#clipped_texture.flags = 0 #turn off filtering #TODO: turn back on if backgrounds are blurry
		texture_rect.texture = clipped_texture

		layer.add_child(texture_rect)
	update_layers()




func update_layers(): #change so we center around the tile #texture_rect, mode = tile_mode
	var vanishing_point = get_vanishing_point()
	var texture_rect_example = pb.get_child(0).get_child(0)
	var texture_size = Vector2(texture_rect_example.texture.get_width(), texture_rect_example.texture.get_height())
	var viewport_rect = get_viewport_rect()
	var scale_zero_motion_offset = ((viewport_rect.size / vs.resolution_scale) - texture_size) * 0.5
	var scale_one_motion_offset = vanishing_point.global_position - (texture_size * 0.5) #global_position + (size - texture_size) * 0.5 level center

	vanishing_point.get_node("BackgroundOutline").custom_minimum_size = texture_size

	for layer in pb.get_children():
		var index = layer.get_index()
		var texture_rect = layer.get_child(0)
		texture_rect.size.x = texture_size.x
		texture_rect.size.y = texture_size.y

		#vanishing_point
		if layer.motion_scale == Vector2.ZERO:
			layer.motion_offset = scale_zero_motion_offset
		elif layer.motion_scale == Vector2.ONE:
			layer.motion_offset = scale_one_motion_offset
		else:
			var factor_x = layer.motion_scale.x
			var factor_y = layer.motion_scale.y
			layer.motion_offset.x = lerp(scale_zero_motion_offset.x, scale_one_motion_offset.x, factor_x)
			layer.motion_offset.y = lerp(scale_zero_motion_offset.y, scale_one_motion_offset.y, factor_y)

		#tile_mode
		var multiple_texture_length_for_oversize = (ceil(size.x / texture.get_width())) * texture.get_width() #doesn't work for motion scales higher than 1.0
		multiple_texture_length_for_oversize += texture.get_width() #add one so we can oversize for animation motion
		var multiple_texture_height_for_oversize = (ceil(size.y / texture.get_height())) * texture.get_height()

		var used_tile_mode = tile_mode
		if index == 0:
			used_tile_mode = back_tile_mode
		match used_tile_mode:
			TileMode.HORIZONTAL:
				texture_rect.size.x = multiple_texture_length_for_oversize
				texture_rect.size.y = texture_rect.texture.get_height()
				layer.motion_offset.x -= multiple_texture_length_for_oversize / 2.0
			TileMode.VERTICAL:
				texture_rect.size.x = texture_rect.texture.get_width()
				texture_rect.size.y = multiple_texture_height_for_oversize
				layer.motion_offset.y -= multiple_texture_height_for_oversize / 2.0
			TileMode.BOTH:
				texture_rect.size.x = multiple_texture_length_for_oversize
				texture_rect.size.y = multiple_texture_height_for_oversize
				layer.motion_offset.x -= multiple_texture_length_for_oversize / 2.0
				layer.motion_offset.y -= multiple_texture_height_for_oversize / 2.0
			TileMode.NONE:
				texture_rect.size.x = texture_rect.texture.get_width()
				texture_rect.size.y = texture_rect.texture.get_height()
		texture_rect_full_size[index] = texture_rect.size

		#layer_height_offset
		layer.motion_offset.y += layer_height_offsets[index]
		layer_base_offset[index] = layer.motion_offset



### GETTERS ###

func get_vanishing_point() -> Node:
	var out
	var vanishing_point_count = 0
	for v in get_tree().get_nodes_in_group("VanishingPoints"):
		out = v
		vanishing_point_count += 1
	if vanishing_point_count == 0:
		printerr("ERROR: LEVEL HAS NO VANISHING POINT FOR PARALLAX BACKGROUND")
	elif vanishing_point_count > 1:
		printerr("ERROR: LEVEL HAS MORE THAN ONE VANISHING POINT FOR PARALLAX BACKGROUND")
	return out

### SIGNALS ###

func on_camera_zoom_changed():
	update_layers()

func _resolution_scale_changed(_resolution_scale):
	emit_signal("limit_camera", offset_left, offset_right, offset_top, offset_bottom)
	#set_focus()
	update_layers()
