extends Node

onready var camera = get_tree().get_root().get_node("World/Juniper/PlayerCamera")

signal limit_camera(left, right, top, bottom)

func _ready():
	add_to_group("CameraLimiters")
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	connect("limit_camera", camera, "_on_limit_camera")
	var left = $Left.position.x 
	var right = $Right.position.x
	var top = $Top.position.y
	var bottom = $Bottom.position.y
	emit_signal("limit_camera", left, right, top, bottom)

func _on_viewport_size_changed():
	var left = $Left.position.x 
	var right = $Right.position.x
	var top = $Top.position.y
	var bottom = $Bottom.position.y
	emit_signal("limit_camera", left, right, top, bottom)
