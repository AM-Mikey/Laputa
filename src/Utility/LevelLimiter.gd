tool
extends MarginContainer



signal limit_camera(left, right, top, bottom)

export var background: StreamTexture

onready var world = get_tree().get_root().get_node("World")
onready var camera = get_tree().get_root().get_node("World/Recruit/PlayerCamera")




func _ready():
	if Engine.editor_hint:
		pass
	else:
		var tr = load("res://src/Background/BackgroundTexture.tscn").instance()
		tr.texture = background
		tr.expand = true
		tr.stretch_mode = TextureRect.STRETCH_TILE
		
		#tr.rect_size = get_tree().get_root().size / world.resolution_scale
		
		world.get_node("Background").add_child(tr)
	
		#add_to_group("CameraLimiters")
		$TextureRect.queue_free()
		get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
		connect("limit_camera", camera, "_on_limit_camera")
		_on_viewport_size_changed()


func _on_viewport_size_changed():
	var left = margin_left
	var right = margin_right
	var top = margin_top
	var bottom = margin_bottom
	emit_signal("limit_camera", left, right, top, bottom)



func _process(delta):
	if Engine.editor_hint:
		$TextureRect.texture = background
	
	
