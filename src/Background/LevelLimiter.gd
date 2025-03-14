#@tool #TODO fix editor script errors
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

var layer_repeating_length := 5000
var always_tile_far_layer = false #DOES NOT WORK

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

	for layer_index in layers:
		var layer = ParallaxLayer.new()
		pb.add_child(layer)
		
		var layer_scale_step = (parallax_near - parallax_far) / (layers - 1)
		var motion_scale = (layer_scale_step * layer_index) + parallax_far
		layer.motion_scale = Vector2(motion_scale, motion_scale)

		var texture_rect = TextureRect.new()
		#texture_rect.expand = true
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_TILE
		texture_rect.mouse_filter = MOUSE_FILTER_IGNORE


		var layer_height = int(texture.get_height() / float(layers))
		var layer_y = layer_height * layer_index
		#print(layer_y)
		var region = Rect2i(0, layer_y, texture.get_width(), layer_height)
		#print(region)
		
		#this cannot be AtlasTexture due to bug https://github.com/godotengine/godot/issues/20472
		var texture_as_image = texture.get_image()
		var clipped_image = texture_as_image.get_region(region)
		var clipped_texture = ImageTexture.create_from_image(clipped_image)
		
		#get_parent().get_node("TextureRect2").texture = clipped_texture
		#clipped_texture.flags = 0 #turn off filtering #TODO: turn back on if backgrounds are blurry
		texture_rect.texture = clipped_texture
		
		if layer_index == 0 and always_tile_far_layer:
			set_tile_mode(texture_rect, "both")
		else:
			set_tile_mode(texture_rect)
		
		#texture_rect.global_position = texture_rect.size * -0.5 #TODO:FIX
		layer.add_child(texture_rect)
		#await get_tree().process_frame


func set_focus():
	#if not Engine.is_editor_hint():
		#var base_offset_x = ((-w.resolution_scale * global_position.x) + (size.x * w.resolution_scale) - get_viewport().size.x) / 2
		#var base_offset_y = ((-w.resolution_scale * global_position.y) + (size.y * w.resolution_scale) - get_viewport().size.y) / 2 
		#
		#var center = Vector2(base_offset_x, base_offset_y)
		#var near_corner = Vector2i.ZERO	#TODO:FIX
		#var far_corner = Vector2i(texture.get_width() * 2, texture.get_width() * -2) #both this and the last line had stops. i dont understand this right now so im leaving it
		#
		#match focus:
			#Focus.CENTER:	#TODO:FIX
				#pb.scroll_base_offset = center
			#Focus.TOP:
				#pb.scroll_base_offset = Vector2(center.x, far_corner.y)
			#Focus.ONE_QUARTER:
				#pb.scroll_base_offset = Vector2(center.x, far_corner.y + (texture.get_width() * 0.5))
			#Focus.THREE_QUARTERS:
				#pb.scroll_base_offset = Vector2(center.x, far_corner.y + (texture.get_width() * 1.5))
			#Focus.BOTTOM:
				#pb.scroll_base_offset = Vector2(center.x, near_corner.y)
			#
		##pb.scroll_base_offset /=  w.resolution_scale
		
		var limiter_bottom = position.y + size.y
		var texture_layer_height = int(texture.get_height() / float(layers))
		pb.scroll_base_offset.y = (limiter_bottom - texture_layer_height) * w.resolution_scale
		

func set_tile_mode(texture_rect, mode := "auto"):
	match mode:
		"auto":
			match tile_mode:
				TileMode.HORIZONTAL:
					texture_rect.size.x = layer_repeating_length
					texture_rect.size.y = texture_rect.texture.get_height()
					#texture_rect.global_position = texture_rect.size * -0.5 #TODO:FIX
				TileMode.VERTICAL:
					texture_rect.size.x = texture_rect.texture.get_width()
					texture_rect.size.y = layer_repeating_length
					#texture_rect.global_position = texture_rect.size * -0.5
				TileMode.BOTH:
					texture_rect.size.x = layer_repeating_length
					texture_rect.size.y = layer_repeating_length
					#texture_rect.global_position = Vector2.ZERO #texture_rect.global_position = texture_rect.size * -0.5
				TileMode.NONE:
					texture_rect.size.x = texture_rect.texture.get_width()
					texture_rect.size.y = texture_rect.texture.get_height()
					#texture_rect.global_position = Vector2.ZERO #texture_rect.size * 0.5
		"both":
			texture_rect.size.x = layer_repeating_length
			texture_rect.size.y = layer_repeating_length

func on_viewport_size_changed():
	emit_signal("limit_camera", offset_left, offset_right, offset_top, offset_bottom)
	set_focus()
