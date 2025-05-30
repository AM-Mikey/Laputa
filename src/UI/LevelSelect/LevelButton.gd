extends Control

const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
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
	if world.has_node("UILayer/HUD"):
		world.get_node("UILayer/HUD").free()
	
	world.on_level_change(level, -1)
	
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").queue_free()
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").unpause()

	world.add_child(JUNIPER.instantiate())
	world.get_node("UILayer").add_child(HUD.instantiate())
	
	await get_tree().process_frame
	
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		world.get_node("Juniper").global_position = s.global_position
	
	world.get_node("UILayer/LevelSelect").queue_free()
