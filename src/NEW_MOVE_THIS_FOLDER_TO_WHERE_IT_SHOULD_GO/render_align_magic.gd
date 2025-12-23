extends Control

@onready var sub_viewport: SubViewport = %SubViewport
@onready var camera: Camera2D = %Camera2D
@onready var base_position: Node2D = %"base position"
@onready var offset: Node2D = %offset

func _ready() -> void:
	sub_viewport.world_2d = get_world_2d()

func _physics_process(delta: float) -> void:
	print(base_position.global_position)
