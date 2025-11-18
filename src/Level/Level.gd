extends Node2D

const DB = preload("res://src/Dialog/DialogBox.tscn")
const KILL_BOX = preload("res://src/Trigger/KillBox.tscn")
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
	setup_kill_box()

	if level_type == LevelType.PLAYERLESS_CUTSCENE:
		do_playerless_cutscene()

	if not am.music_queue.is_empty():
		await am.fadeout_finished
	if not w.has_node("UILayer/UIGroup/TitleScreen"):
		if music == "":
			pass
		else:
			am.play_music(music)


func do_playerless_cutscene():
	if w.has_node("UILayer/UIGroup/DialogBox"): #clear old dialog box if there is one
		w.get_node("UILayer/UIGroup/DialogBox").exit()

	var dialog_box = DB.instantiate()
	dialog_box.connect("dialog_finished", Callable(self, "on_dialog_finished"))
	get_tree().get_root().get_node("World/UIGroup/UILayer").add_child(dialog_box)
	dialog_box.start_printing(dialog_json, conversation)
	print("starting conversation")

func setup_kill_box():
	var kill_box = KILL_BOX.instantiate()
	var ll = get_node("LevelLimiter")
	var bottom_distance = ll.global_position.y + ll.size.y
	var forgiveness = 64
	kill_box.global_position = Vector2(ll.global_position.x, bottom_distance + forgiveness)
	kill_box.get_node("CollisionShape2D").position = Vector2.ZERO
	kill_box.get_node("CollisionShape2D").shape.size = Vector2(ll.size.x, 16)
	$Triggers.add_child(kill_box)
	print("added kb")

func exit_level():
	queue_free()

func save_changes():
	var ll = get_node("LevelLimiter")
	ll.background_resource.texture = ll.texture
	ll.background_resource.layers = ll.layers
	ll.background_resource.layer_scales = ll.layer_scales
	ll.background_resource.layer_height_offsets = ll.layer_height_offsets
	ll.background_resource.horizontal_speed = ll.horizontal_speed
	ll.background_resource.focus = ll.focus
	ll.background_resource.tile_mode = ll.tile_mode
	ll.background_resource.back_tile_mode = ll.back_tile_mode
