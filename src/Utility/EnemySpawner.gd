extends Node2D

export var spawn_time = 3.0
export var enemy = "res://src/Actor/Enemy/Roller.tscn"

func _ready():
	$Timer.start(spawn_time)

func _on_Timer_timeout():
	var enemy_instance = load(enemy).instance()
	enemy_instance.position = position
	get_parent().get_node("Actors").add_child(enemy_instance)
	$Timer.start(spawn_time)
