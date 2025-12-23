extends Control

@onready var sub_viewport: SubViewport = %SubViewport
@onready var camera: Camera2D = %Camera2D

func _ready() -> void:
	sub_viewport.world_2d = get_world_2d()
