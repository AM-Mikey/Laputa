extends Node

const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const EDITOR_CAMERA = preload("res://src/Editor/EditorCamera.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const LEVEL_EDITOR = preload("res://src/Editor/LevelEditor.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")

onready var world = get_tree().get_root().get_node("World")
onready var ui = world.get_node("UILayer")

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func _input(event):
	if event.is_action_pressed("debug_editor"):
		if ui.has_node("LevelEditor"):
			ui.get_node("EditorCamera").queue_free()
			ui.get_node("LevelEditor").queue_free()
			ui.add_child(HUD.instance())
			world.get_node("Juniper/PlayerCamera").current = true
		else:
			ui.add_child(LEVEL_EDITOR.instance())
			ui.add_child(EDITOR_CAMERA.instance())
			ui.get_node("HUD").queue_free()
	
	if event.is_action_pressed("debug_print"):
		debug_print()

	if event.is_action_pressed("debug_reload"):
		reload_level()

	if event.is_action_pressed("debug_triggers"):
		world.visible_triggers = !world.visible_triggers
		for v in get_tree().get_nodes_in_group("TriggerVisuals"):
			v.visible = world.visible_triggers
#
	if event.is_action_pressed("debug_quit"):
		get_tree().quit()

	if event.is_action_pressed("debug_save"):
		var popup = POPUP.instance()
		popup.text = "quicksaved..."
		ui.add_child(popup)
		world.write_level_data_to_temp()
		world.write_player_data_to_save()
		world.copy_level_data_from_temp_to_save()

	if event.is_action_pressed("debug_load"):
		var popup = POPUP.instance()
		popup.text = "loaded save"
		ui.add_child(popup)
		world.read_player_data_from_save()
		world.read_level_data_from_save()
		world.copy_level_data_from_save_to_temp()


func debug_print():
	if not ui.has_node("DebugInfo"):
		ui.add_child(DEBUG_INFO.instance())
	else:
		ui.get_node("DebugInfo").queue_free()
#
#
func reload_level():
	if ui.has_node("PauseMenu"):
		ui.get_node("PauseMenu").unpause()
	
	world.get_node("Juniper").free() #we free and respawn them so we have a clean slate when we load in
	ui.get_node("HUD").free()
	world.on_level_change(load(world.current_level.filename), 0)


	world.add_child(JUNIPER.instance())
	ui.add_child(HUD.instance())

	yield(get_tree(), "idle_frame")

	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		world.get_node("Juniper").global_position = s.global_position