@tool #TODO fix editor script errors
extends MarginContainer

signal limit_camera(left, right, top, bottom)

enum Focus {TOP, ONE_QUARTER, CENTER, THREE_QUARTERS, BOTTOM}
enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}

@export var texture: CompressedTexture2D
@export var layers := 1
@export var parallax_near := 0.8
@export var parallax_far := 0.0
@export var focus: Focus
@export var tile_mode: TileMode

var layer_repeating_length := 4000
var always_tile_far_layer = true

var w
var camera
var pb



func _ready():
	if not Engine.is_editor_hint():
		
		w = get_tree().get_root().get_node("World")
		camera = w.get_node("Juniper/PlayerCamera")
		pb = w.get_node("ParallaxBackground")
		
		$TextureRect.queue_free()
		setup_layers()
		set_focus()
		
	#add_to_group("CameraLimiters")

	
	if not camera:
		camera = get_tree().get_root().get_node_or_null("World/Juniper/PlayerCamera")
	if camera:
		connect("limit_camera", Callable(camera, "_on_limit_camera"))
		
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()

func _process(_delta):
	if Engine.is_editor_hint():
		$TextureRect.texture = texture #TODO: bad way of doing this, use setget instead



func setup_layers():
	for c in pb.get_children():
		c.free()

	var layer_id = 0
	for i in layers:
		var layer = ParallaxLayer.new()
		pb.add_child(layer)
		
		var motion_scale = (parallax_near - parallax_far) / layers * layer_id
		layer.motion_scale = Vector2(motion_scale, motion_scale)

		var texture_rect = TextureRect.new()
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_TILE
		texture_rect.mouse_filter = MOUSE_FILTER_IGNORE

#		var atlas_texture = AtlasTexture.new()
#		atlas_texture.atlas = texture
		var layer_height = int(texture.get_height() / float(layers))
		var layer_y = layer_height * layer_id
		var region = Rect2(0, layer_y, texture.get_width(), layer_height)
		
		var clipped_texture = ImageTexture.new()
		clipped_texture.create_from_image(texture.get_image().get_region(region))
		#clipped_texture.flags = 0 #turn off filtering #TODO: turn back on if backgrounds are blurry
		texture_rect.texture = clipped_texture
		
		if layer_id == 0 and always_tile_far_layer:
			set_tile_mode(texture_rect, "both")
		else:
			set_tile_mode(texture_rect)
		
		texture_rect.global_position = texture_rect.size * -0.5
		layer.add_child(texture_rect)
		layer_id += 1


func set_focus():
	if not Engine.is_editor_hint():
		var center = global_position + (size / 2)
		var near_corner = global_position
		var far_corner = global_position + size
		
		match focus:
			Focus.CENTER:
				pb.scroll_base_offset = center
			Focus.TOP:
				pb.scroll_base_offset = Vector2(center.x, 0)
			Focus.ONE_QUARTER:
				pb.scroll_base_offset = Vector2(center.x, near_corner.y + (size.y * .25))
			Focus.THREE_QUARTERS:
				pb.scroll_base_offset = Vector2(center.x, near_corner.y + (size.y * .75))
			Focus.BOTTOM:
				pb.scroll_base_offset = Vector2(center.x, far_corner.y)
			
		pb.scroll_base_offset *=  w.resolution_scale

func set_tile_mode(texture_rect, mode := "auto"):
	match mode:
		"auto":
			match tile_mode:
				TileMode.HORIZONTAL:
					texture_rect.size.x = layer_repeating_length
					texture_rect.size.y = texture_rect.texture.get_height()
				TileMode.VERTICAL:
					texture_rect.size.x = texture_rect.texture.get_width()
					texture_rect.size.y = layer_repeating_length
				TileMode.BOTH:
					texture_rect.size.x = layer_repeating_length
					texture_rect.size.y = layer_repeating_length
				TileMode.NONE:
					texture_rect.size.x = texture_rect.texture.get_width()
					texture_rect.size.y = texture_rect.texture.get_height()
		"both":
			texture_rect.size.x = layer_repeating_length
			texture_rect.size.y = layer_repeating_length

func on_viewport_size_changed():
	emit_signal("limit_camera", offset_left, offset_right, offset_top, offset_bottom)
	set_focus()
