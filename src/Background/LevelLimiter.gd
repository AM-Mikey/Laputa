tool
extends MarginContainer

signal limit_camera(left, right, top, bottom)

enum Focus {TOP, ONE_QUARTER, CENTER, THREE_QUARTERS, BOTTOM}
enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}

export var texture: StreamTexture
export var layers := 1
export var parallax_near := 0.8
export var parallax_far := 0.0
export(Focus) var focus
export(TileMode) var tile_mode

var layer_repeating_length := 4000
var always_tile_far_layer = true

onready var w = get_tree().get_root().get_node("World")
onready var pb = w.get_node("ParallaxBackground")
onready var camera = w.get_node_or_null("Juniper/PlayerCamera")



func _ready():
	if not Engine.editor_hint:
		$TextureRect.queue_free()
		setup_layers()
		set_focus()
		
	#add_to_group("CameraLimiters")

	
	if not camera:
		camera = get_tree().get_root().get_node_or_null("World/Juniper/PlayerCamera")
	if camera:
		connect("limit_camera", camera, "_on_limit_camera")
		
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()

func _process(_delta):
	if Engine.editor_hint:
		$TextureRect.texture = texture #TODO: bad way of doing this, use setget instead



func setup_layers():
	for c in pb.get_children():
		c.free()

	var layer_id = 0
	for i in layers:
		var layer = ParallaxLayer.new()
		w.get_node("ParallaxBackground").add_child(layer)
		
		var motion_scale = (parallax_near - parallax_far) / layers * layer_id
		layer.motion_scale = Vector2(motion_scale, motion_scale)

		var tr = TextureRect.new()
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.mouse_filter = MOUSE_FILTER_IGNORE

#		var atlas_texture = AtlasTexture.new()
#		atlas_texture.atlas = texture
		var layer_height = texture.get_height() / layers
		var layer_y = layer_height * layer_id
		var region = Rect2(0, layer_y, texture.get_width(), layer_height)
		
		var clipped_texture = ImageTexture.new()
		clipped_texture.create_from_image(texture.get_data().get_rect(region))
		clipped_texture.flags = 0 #turn off filtering
		tr.texture = clipped_texture
		
		if layer_id == 0 and always_tile_far_layer:
			set_tile_mode(tr, "both")
		else:
			set_tile_mode(tr)
		
		tr.rect_global_position = tr.rect_size * -0.5
		layer.add_child(tr)
		layer_id += 1


func set_focus():
	var center = rect_global_position + (rect_size / 2)
	var near_corner = rect_global_position
	var far_corner = rect_global_position + rect_size
	
	match focus:
		Focus.CENTER:
			pb.scroll_base_offset = center
		Focus.TOP:
			pb.scroll_base_offset = Vector2(center.x, 0)
		Focus.ONE_QUARTER:
			pb.scroll_base_offset = Vector2(center.x, near_corner.y + (rect_size.y * .25))
		Focus.THREE_QUARTERS:
			pb.scroll_base_offset = Vector2(center.x, near_corner.y + (rect_size.y * .75))
		Focus.BOTTOM:
			pb.scroll_base_offset = Vector2(center.x, far_corner.y)
		
	pb.scroll_base_offset *=  w.resolution_scale

func set_tile_mode(tr, mode := "auto"):
	match mode:
		"auto":
			match tile_mode:
				TileMode.HORIZONTAL:
					tr.rect_size.x = layer_repeating_length
					tr.rect_size.y = tr.texture.get_height()
				TileMode.VERTICAL:
					tr.rect_size.x = tr.texture.get_width()
					tr.rect_size.y = layer_repeating_length
				TileMode.BOTH:
					tr.rect_size.x = layer_repeating_length
					tr.rect_size.y = layer_repeating_length
				TileMode.NONE:
					tr.rect_size.x = tr.texture.get_width()
					tr.rect_size.y = tr.texture.get_height()
		"both":
			tr.rect_size.x = layer_repeating_length
			tr.rect_size.y = layer_repeating_length

func on_viewport_size_changed():
	emit_signal("limit_camera", margin_left, margin_right, margin_top, margin_bottom)
	set_focus()
