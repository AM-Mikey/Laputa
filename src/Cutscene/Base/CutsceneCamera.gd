extends Camera2D

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = f.pc()
@onready var previous_camera_pos = pc.get_node("PlayerCamera").get_screen_center_position()

func _ready():
	global_position = previous_camera_pos
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	await get_tree().process_frame
	await get_tree().process_frame
	position_smoothing_enabled = true

func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
