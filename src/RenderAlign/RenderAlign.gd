extends Control

@onready var sub_viewport: SubViewport = %SubViewport
@onready var camera: Camera2D = %Camera2D
@onready var base_position: Node2D = %BasePosition


func _ready() -> void:
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	sub_viewport.world_2d = get_world_2d()
	get_viewport().canvas_cull_mask = 1
	sub_viewport.canvas_cull_mask = 2

func _physics_process(_delta: float) -> void:
	var active_cam := get_viewport().get_camera_2d()
	if active_cam == null:
		return
	base_position.global_position = active_cam.get_screen_center_position()
	camera.zoom = active_cam.zoom



### SIGNALS ###

func _resolution_scale_changed(_resolution_scale):
	sub_viewport.size = get_viewport().size + Vector2i(20,20)
