extends Node2D

const DB = preload("res://src/Dialog/DialogBox.tscn")

export var level_name: String
export var music: String

enum LevelType {NORMAL, PLAYERLESS_CUTSCENE}
export(LevelType) var level_type
export (String, FILE, "*.json") var dialog_json: String
export var conversation: String

onready var world = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("Levels")

	if self.has_node("Notes"):
		get_node("Notes").visible = false
		
	if level_type == LevelType.PLAYERLESS_CUTSCENE:
		
		if world.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
			world.get_node("UILayer/DialogBox").stop_printing()
			
		var dialog_box = DB.instance()
		dialog_box.connect("dialog_finished", self, "on_dialog_finished")
		get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
		dialog_box.start_printing(dialog_json, conversation)
		print("starting conversation")



func exit_level():
	queue_free()
