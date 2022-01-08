extends Control

const RECRUIT = preload("res://src/Actor/Player/Recruit.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")


var level: String

onready var world = get_tree().get_root().get_node("World")

func _ready():
	self.text = (level.trim_prefix("res://src/Level/")).trim_suffix(".tscn")
	if level.find("/CloudFactory") != -1:
		self.set("custom_colors/font_color", Color(0.4, 0.666667, 0.8))
	if level.find("/Coast") != -1:
		self.set("custom_colors/font_color", Color(0.8, 0.4, 0.4))
	if level.find("/Village") != -1:
		self.set("custom_colors/font_color", Color(0.534375, 0.8, 0.4))
	


func _on_LevelButton_pressed():
	if world.has_node("Recruit"):
		world.get_node("Recruit").free() #we free and respawn them so we have a clean slate when we load in
	if world.has_node("UILayer/HUD"):
		world.get_node("UILayer/HUD").free()
	
	world.on_level_change(load(level), 0)
	
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").queue_free()
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").unpause()

	world.add_child(RECRUIT.instance())
	world.get_node("UILayer").add_child(HUD.instance())
	
	yield(get_tree(), "idle_frame")
	
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		world.get_node("Recruit").global_position = s.global_position
	
	world.get_node("UILayer/LevelSelect").queue_free()
