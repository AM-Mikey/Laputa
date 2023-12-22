extends Node

const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const LEVEL_EDITOR = preload("res://src/Editor/Editor.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")
const SHOP_MENU = preload("res://src/UI/ShopMenu/ShopMenu.tscn")

@onready var world = get_tree().get_root().get_node("World")
@onready
var ui = world.get_node("UILayer")
@onready var el = world.get_node("EditorLayer")
@onready var dl = world.get_node("DebugLayer")

var editor_tab = 0 #to save when we re-enter the editor

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("debug_editor"):
		if el.has_node("Editor"):
			editor_tab = el.get_node("Editor/Main/Tab").current_tab
			el.get_node("Editor").exit()
		else:
			print("showing level editor")
			el.add_child(LEVEL_EDITOR.instantiate())
			el.get_node("Editor/Main/Tab").current_tab = editor_tab
			el.get_node("Editor").on_tab_changed(editor_tab)
	
	if event.is_action_pressed("debug_print"):
		debug_print()


	if event.is_action_pressed("debug_reload"):
		if el.has_node("Editor"):
			el.get_node("Editor").disabled = true
		reload_level()
		await get_tree().process_frame
		if el.has_node("Editor"):
			el.get_node("Editor").setup_level()
			el.get_node("Editor").disabled = false


	if event.is_action_pressed("debug_triggers"):
		world.set_debug_visible()


	if event.is_action_pressed("debug_quit"):
		if not el.has_node("Editor"):
			print("quitting...")
			get_tree().quit()


	if event.is_action_pressed("debug_save"):
		var popup = POPUP.instantiate()
		popup.text = "quicksaved..."
		ui.add_child(popup)
		world.write_level_data_to_temp()
		world.write_player_data_to_save()
		world.copy_level_data_from_temp_to_save()


	if event.is_action_pressed("debug_load"):
		var popup = POPUP.instantiate()
		popup.text = "loaded save"
		ui.add_child(popup)
		world.read_player_data_from_save()
		world.read_level_data_from_save()
		world.copy_level_data_from_save_to_temp()

	if event.is_action_pressed("debug_shop"):
		var shop_menu = SHOP_MENU.instantiate()
		ui.add_child(shop_menu)


	if event.is_action_pressed("debug_fly"):
		if world.has_node("Juniper"):
			var pc = world.get_node("Juniper")
			if pc.mm.current_state != pc.mm.states["fly"]:
				pc.mm.cached_state = pc.mm.current_state
				pc.mm.change_state("fly")
			else:
				pc.mm.change_state(pc.mm.cached_state.name.to_lower())



func debug_print():
	if not dl.has_node("DebugInfo"):
		print("showing debug info")
		dl.add_child(DEBUG_INFO.instantiate())
	else:
		dl.get_node("DebugInfo").queue_free()
#
#
func reload_level():
	print("reloading level")
	if ui.has_node("PauseMenu"):
		ui.get_node("PauseMenu").unpause()
	
	world.get_node("Juniper").free() #we free and respawn them so we have a clean slate when we load in
	if ui.has_node("HUD"):
		ui.get_node("HUD").free()
	world.on_level_change(load(world.current_level.scene_file_path), 0)


	world.add_child(JUNIPER.instantiate())
	ui.add_child(HUD.instantiate())

	await get_tree().process_frame

	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		world.get_node("Juniper").global_position = s.global_position
