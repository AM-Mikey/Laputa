extends Control

const JUNIPER = preload("res://src/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")


var level: String

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	self.text = (level.trim_prefix("res://src/Level/")).trim_suffix(".tscn")
	if level.find("/CloudFactory") != -1:
		self.set("theme_override_colors/font_color", Color(0.4, 0.666667, 0.8))
	if level.find("/Coast") != -1:
		self.set("theme_override_colors/font_color", Color(0.8, 0.4, 0.4))
	if level.find("/Village") != -1:
		self.set("theme_override_colors/font_color", Color(0.534375, 0.8, 0.4))
	


func _on_LevelButton_pressed():
	if world.has_node("Juniper"):
		world.get_node("Juniper").free() #we free and respawn them so we have a clean slate when we load in
	if world.has_node("UILayer/UIGroup/HUD"):
		world.get_node("UILayer/UIGroup/HUD").free()
	
	world.change_level_via_code(level)
	
	if world.has_node("UILayer/UIGroup/TitleScreen"):
		world.get_node("UILayer/UIGroup/TitleScreen").queue_free()
	if world.has_node("UILayer/UIGroup/PauseMenu"):
		world.get_node("UILayer/UIGroup/PauseMenu").unpause()
	world.get_node("UILayer/UIGroup/LevelSelect").queue_free()
