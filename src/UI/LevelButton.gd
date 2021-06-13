extends Control


onready var world = get_tree().get_root().get_node("World")

var level = "res://src/Level/Demo/01PirateCliff.tscn"

func _ready():
	$Button.text = "..." + (level.trim_prefix("res://src/Level")).trim_suffix(".tscn")


func _on_Button_pressed():
	world._on_level_change(level, 0, "LevelSelect", "res://assets/Music/XXXX.ogg")
	get_parent().get_parent().get_parent().get_parent().visible = false
	world.get_node("Recruit").visible = true
	world.get_node("Recruit").disabled = false
	world.get_node("UILayer/HUD").visible = true
	
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		world.get_node("Recruit").position = s.global_position
