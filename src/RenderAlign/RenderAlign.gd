extends Control

@onready var sub_viewport: SubViewport = %SubViewport
@onready var camera: Camera2D = %Camera2D
@onready var base_position: Node2D = %"base position"

func _viewport_size_changed():
	sub_viewport.size = get_viewport().size + Vector2i(20,20)

func _ready() -> void:
	var _err = get_tree().root.connect("size_changed", Callable(self, "_viewport_size_changed"))
	_viewport_size_changed()
	sub_viewport.world_2d = get_world_2d()
	get_viewport().canvas_cull_mask = 1
	sub_viewport.canvas_cull_mask = 2

func _physics_process(_delta: float) -> void:
	var active_cam := get_viewport().get_camera_2d()
	base_position.global_position = active_cam.get_screen_center_position()
	camera.zoom = active_cam.zoom
