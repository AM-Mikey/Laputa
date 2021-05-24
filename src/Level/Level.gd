extends Node2D

export var level_name: String
export var music: String

onready var world = get_tree().get_root().get_node("World")

func _ready():
	if self.has_node("Camera2D"):
		$Camera2D.zoom = Vector2(1 / world.resolution_scale, 1 / world.resolution_scale)
	
	if self.has_node("Notes"):
		get_node("Notes").visible = false

func exit_level():
	queue_free()
