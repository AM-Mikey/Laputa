extends Node2D

export var level_name: String
export var music: String

func exit_level():
	queue_free()
