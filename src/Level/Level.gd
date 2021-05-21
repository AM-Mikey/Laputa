extends Node2D

export var level_name: String
export var music: String

func _ready():
	if self.has_node("Notes"):
		get_node("Notes").visible = false

func exit_level():
	queue_free()
