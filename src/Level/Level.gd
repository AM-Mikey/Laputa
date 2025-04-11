extends Node2D

const DB = preload("res://src/Dialog/DialogBox.tscn")
enum LevelType {NORMAL, PLAYERLESS_CUTSCENE}

@export var editor_hidden = false
@export var level_name: String
@export var level_type: LevelType
@export var music: String
@export_file("*.json") var dialog_json: String
@export var conversation: String

var time_created: Dictionary

@onready var w = get_tree().get_root().get_node("World")


func _ready():
	add_to_group("Levels")
	
	if has_node("Notes"):
		get_node("Notes").visible = false
		
	if level_type == LevelType.PLAYERLESS_CUTSCENE:
		do_playerless_cutscene()

	if not am.music_queue.is_empty():
		await am.fadeout_finished
	if not w.has_node("UILayer/TitleScreen"):
		if music == "":
			pass
		else:
			am.play_music(music)


func do_playerless_cutscene():
	if w.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
		w.get_node("UILayer/DialogBox").stop_printing()
	
	var dialog_box = DB.instantiate()
	dialog_box.connect("dialog_finished", Callable(self, "on_dialog_finished"))
	get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
	dialog_box.start_printing(dialog_json, conversation)
	print("starting conversation")


func exit_level():
	queue_free()
