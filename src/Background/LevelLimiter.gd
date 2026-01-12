extends MarginContainer

signal limit_camera(left, right, top, bottom)

enum Focus {TOP, ONE_QUARTER, CENTER, THREE_QUARTERS, BOTTOM}
enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}
enum BackTileMode {DEFAULT, BOTH, HORIZONTAL, VERTICAL, NONE}

@export var background_resource: Background
	#set = set_background_resouce
@export var texture: CompressedTexture2D
@export var layers := 1
@export var layer_scales: Dictionary
@export var layer_height_offsets: Dictionary
@export var horizontal_speed: float = 0.0
@export var focus: Focus
@export var tile_mode: TileMode
@export var back_tile_mode: BackTileMode

var layer_repeating_length := 5000
var camera: Camera2D
var texture_rects: Dictionary

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
	set_tile_mode()
	#set_focus()

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
	#for t in texture_rects:
		#if !is_instance_valid(texture_rects[t]): return
		#texture_rects[t].position.x += horizontal_speed * variance * layer_scales[t].x
		#var texture_width = texture_rects[t].texture.get_width()
		#if texture_rects[t].position.x >= (layer_repeating_length * -0.5) + texture_width \
		#or texture_rects[t].position.x <= (layer_repeating_length * -0.5) - texture_width:
			#set_tile_mode(texture_rects[t]) #reset x position to start

func setup_background_resource():
	#background_resource.texture.emit_changed()
	# TODO: This ignores overrides set directly on the LevelLimiter
	texture = background_resource.texture
	layers = background_resource.layers
	layer_scales = background_resource.layer_scales
	layer_height_offsets = background_resource.layer_height_offsets
	horizontal_speed = background_resource.horizontal_speed
	var focus_index = background_resource.focus
	focus = Focus[Focus.find_key(focus_index)]
	var tile_mode_index = background_resource.tile_mode
	tile_mode = TileMode[TileMode.find_key(tile_mode_index)]
	var back_tile_mode_index = background_resource.back_tile_mode
	back_tile_mode = BackTileMode[BackTileMode.find_key(back_tile_mode_index)]

func setup_layers():
	texture_rects.clear()
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

		#var test = Sprite2D.new()
		#test.texture = clipped_texture
		#w.front.add_child(test)

		#clipped_texture.flags = 0 #turn off filtering #TODO: turn back on if backgrounds are blurry
		texture_rect.texture = clipped_texture


		#if layer_index == 0:
			#match back_tile_mode:
				#BackTileMode.DEFAULT:
					#set_tile_mode(texture_rect)
				#BackTileMode.HORIZONTAL:
					#set_tile_mode(texture_rect, TileMode.HORIZONTAL)
				#BackTileMode.VERTICAL:
					#set_tile_mode(texture_rect, TileMode.VERTICAL)
				#BackTileMode.BOTH:
					#set_tile_mode(texture_rect, TileMode.BOTH)
				#BackTileMode.NONE:
					#set_tile_mode(texture_rect, TileMode.NONE)
		#else:
			#set_tile_mode(texture_rect)
		texture_rect.position.y += layer_height_offsets[layer_index]
		texture_rects[layer_index] = texture_rect
		layer.add_child(texture_rect)
	set_tile_mode()


#func set_focus(res_scale = vs.resolution_scale):
	#print("sad")
	#var vanishing_point: Node
	#var vanishing_point_count = 0
	#for v in get_tree().get_nodes_in_group("VanishingPoints"):
		#vanishing_point = v
		#vanishing_point_count += 1
	#if vanishing_point_count == 0:
		#printerr("ERROR: LEVEL HAS NO VANISHING POINT FOR PARALLAX BACKGROUND")
	#elif vanishing_point_count > 1:
		#printerr("ERROR: LEVEL HAS MORE THAN ONE VANISHING POINT FOR PARALLAX BACKGROUND")

	#var texture_layer_height = int(texture.get_height() / float(layers))
	#pb.scroll_base_offset.x = (vanishing_point.global_position.x) * res_scale
	#pb.scroll_base_offset.y = (vanishing_point.global_position.y - texture_layer_height) * res_scale


	#if camera:
		#if camera.name == "EditorCamera":
			#res_scale = camera.zoom.x
	#var limiter_top = position.y
	#var limiter_one_quarter = position.y + (size.y * 0.25)
	#var limiter_center = position.y + (size.y * 0.5)
	#var limiter_three_quarters = position.y + (size.y * 0.75)
	#var limiter_bottom = position.y + size.y

#
	#match focus:
		#Focus.TOP:
			#pb.scroll_base_offset.y = limiter_top * res_scale
		#Focus.ONE_QUARTER:
			#pb.scroll_base_offset.y = (limiter_one_quarter - (texture_layer_height * 0.25)) * res_scale
		#Focus.CENTER:
			#pb.scroll_base_offset.y = (limiter_center - (texture_layer_height * 0.5)) * res_scale
		#Focus.THREE_QUARTERS:
			#pb.scroll_base_offset.y = (limiter_three_quarters - (texture_layer_height * 0.75)) * res_scale
		#Focus.BOTTOM:
			#pb.scroll_base_offset.y = (limiter_bottom - texture_layer_height) * res_scale


func set_tile_mode(): #change so we center around the tile #texture_rect, mode = tile_mode
	var vanishing_point: Node
	var vanishing_point_count = 0
	for v in get_tree().get_nodes_in_group("VanishingPoints"):
		vanishing_point = v
		vanishing_point_count += 1
	if vanishing_point_count == 0:
		printerr("ERROR: LEVEL HAS NO VANISHING POINT FOR PARALLAX BACKGROUND")
	elif vanishing_point_count > 1:
		printerr("ERROR: LEVEL HAS MORE THAN ONE VANISHING POINT FOR PARALLAX BACKGROUND")

	var texture_rect_example = pb.get_child(0).get_child(0)
	var texture_size = Vector2(texture_rect_example.texture.get_width(), texture_rect_example.texture.get_height())
	var viewport_rect = get_viewport_rect()
	var scale_zero_motion_offset = ((viewport_rect.size / vs.resolution_scale) - texture_size) * 0.5
	var scale_one_motion_offset = vanishing_point.global_position - (texture_size * 0.5) #global_position + (size - texture_size) * 0.5 level center

	vanishing_point.get_node("BackgroundOutline").custom_minimum_size = texture_size

	for layer in pb.get_children():
		var texture_rect = layer.get_child(0)

		texture_rect.size.x = texture_size.x
		texture_rect.size.y = texture_size.y


		if layer.motion_scale == Vector2.ZERO:
			layer.motion_offset = scale_zero_motion_offset
		elif layer.motion_scale == Vector2.ONE:
			layer.motion_offset = scale_one_motion_offset
		else:
			var factor_x = layer.motion_scale.x
			var factor_y = layer.motion_scale.y
			layer.motion_offset.x = lerp(scale_zero_motion_offset.x, scale_one_motion_offset.x, factor_x)
			layer.motion_offset.y = lerp(scale_zero_motion_offset.y, scale_one_motion_offset.y, factor_y)
	#layer.motion_offset.x = texture_size.x - size.x
	#layer.motion_offset.y = texture_size.y - size.y
	#match mode:
		#TileMode.HORIZONTAL:
			#texture_rect.size.x = layer_repeating_length
			#texture_rect.position.x = layer_repeating_length * -0.5
			#texture_rect.size.y = texture_rect.texture.get_height()
		#TileMode.VERTICAL:
			#texture_rect.size.x = texture_rect.texture.get_width()
			#texture_rect.size.y = layer_repeating_length
			#texture_rect.position.y = (texture_rect.size.y / 2.0) * -1.0
		#TileMode.BOTH:
			#texture_rect.size.x = layer_repeating_length
			#texture_rect.position.x = (texture_rect.size.x / 2.0) * -1.0
			#texture_rect.size.y = layer_repeating_length
			#texture_rect.position.y = (texture_rect.size.y / 2.0) * -1.0
		#TileMode.NONE:
			#texture_rect.size.x = texture_rect.texture.get_width()
			#texture_rect.size.y = texture_rect.texture.get_height()

func on_camera_zoom_changed():
	set_tile_mode()

func _resolution_scale_changed(_resolution_scale):
	emit_signal("limit_camera", offset_left, offset_right, offset_top, offset_bottom)
	#set_focus()
	set_tile_mode()
