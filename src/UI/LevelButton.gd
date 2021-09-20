extends Control


onready var world = get_tree().get_root().get_node("World")

var level = "res://src/Level/Demo/01PirateCliff.tscn"

func _ready():
	self.text = (level.trim_prefix("res://src/Level/")).trim_suffix(".tscn") #"..." + 
	if level.find("/CloudFactory") != -1:
		self.set("custom_colors/font_color", Color(0.4, 0.666667, 0.8))
	if level.find("/Coast") != -1:
		self.set("custom_colors/font_color", Color(0.8, 0.4, 0.4))
	if level.find("/Village") != -1:
		self.set("custom_colors/font_color", Color(0.534375, 0.8, 0.4))
	


func _on_LevelButton_pressed():
	world.on_level_change(level, 0, "LevelSelect", "res://assets/Music/XXXX.ogg")
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").queue_free()
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").unpause()
	world.get_node("Recruit").visible = true
	world.get_node("Recruit").disabled = false
	world.get_node("UILayer/HUD").visible = true
	
	yield(get_tree(), "idle_frame")
	
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		world.get_node("Recruit").global_position = s.global_position
		print("moving to position")
		print(s.global_position)
	
	world.get_node("UILayer/LevelSelect").queue_free()
