extends Control

@onready var sub_viewport: SubViewport = %SubViewport
@onready var camera: Camera2D = %Camera2D
@onready var rounder: Node2D = %rounder
@onready var base_position: Node2D = %"base position"

func _ready() -> void:
	sub_viewport.world_2d = get_world_2d()
