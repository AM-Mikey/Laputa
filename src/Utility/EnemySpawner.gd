extends Node2D

export var spawn_time = 3.0
export var enemy = "res://src/Actor/Enemy/Roller.tscn"

func _ready():
	var file_check = File.new()
	if not file_check.file_exists(enemy):
		printerr("ERROR: invalid enemy applied to spawner")
		queue_free()
	$Timer.start(spawn_time)


func _on_Timer_timeout():
	var enemy_instance = load(enemy).instance()
	enemy_instance.position = position
	for l in get_tree().get_nodes_in_group("Levels"):
		l.get_node("Actors").add_child(enemy_instance)
	$Timer.start(spawn_time)
