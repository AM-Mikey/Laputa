extends MarginContainer

signal limit_camera(left, right, top, bottom)

enum Focus {TOP, ONE_QUARTER, CENTER, THREE_QUARTERS, BOTTOM}
enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}
enum FarBackTileMode {DEFAULT, BOTH, HORIZONTAL, VERTICAL, NONE}

@export var background_resource: Background:
	set = set_background_resouce
@export var texture: CompressedTexture2D
@export var layers := 1
@export var layer_scales: Dictionary
@export var focus: Focus
@export var tile_mode: TileMode
@export var far_back_tile_mode: FarBackTileMode

var layer_repeating_length := 5000
var camera: Node

@onready var w = get_tree().get_root().get_node("World")
@onready var pb = w.get_node("ParallaxBackground")



func _ready():
	setup()

func setup():
	set_background_resouce(background_resource) #load the resouce on start
	setup_layers()
	set_focus()
	camera = get_viewport().get_camera_2d()
	if camera:
		connect("limit_camera", Callable(camera, "on_limit_camera"))
		if camera.name == "EditorCamera":
			camera.connect("camera_zoom_changed", Callable(self, "on_camera_zoom_changed"))
	get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	

func set_background_resouce(value): #note this goes through inspector on_changed code first, and then does setup_layers, setup_focus from there
	background_resource = value
	texture = value.texture
	layers = value.layers
	layer_scales = value.layer_scales
	focus = value.focus
	tile_mode = value.tile_mode


func setup_layers():
	for c in pb.get_children():
		c.free()

	for layer_index in layers:
		var layer = ParallaxLayer.new()
		pb.add_child(layer)
		if layer_scales.has(layer_index):
			layer.motion_scale = layer_scales[layer_index]
		else:
			layer.motion_scale = Vector2.ZERO

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
		
		if layer_index == 0:
			match far_back_tile_mode:
				FarBackTileMode.DEFAULT:
					set_tile_mode(texture_rect)
				FarBackTileMode.HORIZONTAL:
					set_tile_mode(texture_rect, TileMode.HORIZONTAL)
				FarBackTileMode.VERTICAL:
					set_tile_mode(texture_rect, TileMode.VERTICAL)
				FarBackTileMode.BOTH:
					set_tile_mode(texture_rect, TileMode.BOTH)
				FarBackTileMode.NONE:
					set_tile_mode(texture_rect, TileMode.NONE)
		else:
			set_tile_mode(texture_rect)
		
		layer.add_child(texture_rect)


func set_focus(res_scale = w.resolution_scale):
	if camera:
		if camera.name == "EditorCamera":
			res_scale = camera.zoom.x
	var limiter_top = position.y
	var limiter_one_quarter = position.y + (size.y * 0.25)
	var limiter_center = position.y + (size.y * 0.5)
	var limiter_three_quarters = position.y + (size.y * 0.75)
	var limiter_bottom = position.y + size.y
	var texture_layer_height = int(texture.get_height() / float(layers))
	
	match focus:
		Focus.TOP:
			pb.scroll_base_offset.y = limiter_top * res_scale
		Focus.ONE_QUARTER:
			pb.scroll_base_offset.y = (limiter_one_quarter - (texture_layer_height * 0.25)) * res_scale
		Focus.CENTER:
			pb.scroll_base_offset.y = (limiter_center - (texture_layer_height * 0.5)) * res_scale
		Focus.THREE_QUARTERS:
			pb.scroll_base_offset.y = (limiter_three_quarters - (texture_layer_height * 0.75)) * res_scale
		Focus.BOTTOM:
			pb.scroll_base_offset.y = (limiter_bottom - texture_layer_height) * res_scale


func set_tile_mode(texture_rect, mode = tile_mode):
	match mode:
		TileMode.HORIZONTAL:
			texture_rect.size.x = layer_repeating_length
			texture_rect.position.x = (layer_repeating_length / 2.0) * -1
			texture_rect.size.y = texture_rect.texture.get_height()
		TileMode.VERTICAL:
			texture_rect.size.x = texture_rect.texture.get_width()
			texture_rect.size.y = layer_repeating_length
			texture_rect.position.y = (layer_repeating_length / 2.0) * -1
		TileMode.BOTH:
			texture_rect.size.x = layer_repeating_length
			texture_rect.position.x = (layer_repeating_length / 2.0) * -1
			texture_rect.size.y = layer_repeating_length
			texture_rect.position.y = (layer_repeating_length / 2.0) * -1
		TileMode.NONE:
			texture_rect.size.x = texture_rect.texture.get_width()
			texture_rect.size.y = texture_rect.texture.get_height()

func on_viewport_size_changed():
	emit_signal("limit_camera", offset_left, offset_right, offset_top, offset_bottom)
	set_focus()

func on_camera_zoom_changed():
	set_focus()
