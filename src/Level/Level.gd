tool
extends Node2D

signal tile_set_changed

const DB = preload("res://src/Dialog/DialogBox.tscn")
enum LevelType {NORMAL, PLAYERLESS_CUTSCENE}

export var level_name: String
export(LevelType) var level_type
export(TileSet) var tile_set setget on_tile_set_changed
export var music: String
export (String, FILE, "*.json") var dialog_json: String
export var conversation: String

var time_created: Dictionary

onready var w = get_tree().get_root().get_node("World")


func _ready():
	add_to_group("Levels")
	
	if not Engine.editor_hint:
		if not w.has_node("UILayer/TitleScreen"):
			if music == "":
				am.play_music("none")
			else:
				am.play_music(music)

		if self.has_node("Notes"):
			get_node("Notes").visible = false
			
		if level_type == LevelType.PLAYERLESS_CUTSCENE:
			do_playerless_cutscene()


func on_tile_set_changed(new):
	tile_set = new
	emit_signal("tile_set_changed")

func do_playerless_cutscene():
	if w.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
		w.get_node("UILayer/DialogBox").stop_printing()
	
	var dialog_box = DB.instance()
	dialog_box.connect("dialog_finished", self, "on_dialog_finished")
	get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
	dialog_box.start_printing(dialog_json, conversation)
	print("starting conversation")


func exit_level():
	queue_free()
