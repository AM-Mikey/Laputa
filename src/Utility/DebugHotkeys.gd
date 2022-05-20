extends Node

const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const LEVEL_EDITOR = preload("res://src/Editor/Editor.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")
const SHOP_MENU = preload("res://src/UI/ShopMenu/ShopMenu.tscn")

onready var world = get_tree().get_root().get_node("World")
onready var ui = world.get_node("UILayer")
onready var el = world.get_node("EditorLayer")

var editor_tab = 0 #to save when we re-enter the editor

func _ready():
	pause_mode = PAUSE_MODE_PROCESS

func _input(event):
	if event.is_action_pressed("debug_editor"):
		if el.has_node("Editor"):
			editor_tab = el.get_node("Editor/Main/Tab").current_tab
			el.get_node("Editor").exit()
		else:
			el.add_child(LEVEL_EDITOR.instance())
			el.get_node("Editor/Main/Tab").current_tab = editor_tab
			el.get_node("Editor").on_tab_changed(editor_tab)
	
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

	if event.is_action_pressed("debug_shop"):
		var shop_menu = SHOP_MENU.instance()
		ui.add_child(shop_menu)

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
	if ui.has_node("HUD"):
		ui.get_node("HUD").free()
	world.on_level_change(load(world.current_level.filename), 0)


	world.add_child(JUNIPER.instance())
	ui.add_child(HUD.instance())

	yield(get_tree(), "idle_frame")

	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		world.get_node("Juniper").global_position = s.global_position
