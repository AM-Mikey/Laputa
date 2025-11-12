extends Node

const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const JUNIPER = preload("res://src/Player/Juniper.tscn")
const LEVEL_EDITOR = preload("res://src/Editor/Editor.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")
const SHOP_MENU = preload("res://src/UI/ShopMenu/ShopMenu.tscn")

@onready var w = get_tree().get_root().get_node("World")

var editor_tab = 0 #to save when we re-enter the editor

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("debug_editor"):
		if w.el.has_node("Editor"):
			editor_tab = w.el.get_node("Editor/Main/Win/Tab").current_tab
			w.el.get_node("Editor").exit()
		else:
			print("showing level editor")
			w.el.add_child(LEVEL_EDITOR.instantiate())
			w.el.get_node("Editor/Main/Win/Tab").current_tab = editor_tab
			w.el.get_node("Editor").on_tab_changed(editor_tab)

	if event.is_action_pressed("debug_print"):
		debug_print()


	if event.is_action_pressed("debug_reload"):
		if w.el.has_node("Editor"):
			w.el.get_node("Editor").disabled = true
		reload_level()
		await get_tree().process_frame
		if w.el.has_node("Editor"):
			w.el.get_node("Editor").setup_level()
			w.el.get_node("Editor").disabled = false


	if event.is_action_pressed("debug_triggers"):
		w.set_debug_visible()


	if event.is_action_pressed("debug_quit"):
		print("quitting...")
		get_tree().quit()

	if not w.el.has_node("Editor"): #non-editor only commands

		if event.is_action_pressed("debug_save"):
			var popup = POPUP.instantiate()
			popup.text = "quicksaved..."
			w.uig.add_child(popup)
			SaveSystem.write_level_data_to_temp(w.current_level)
			SaveSystem.write_player_data_to_save(w.current_level)
			SaveSystem.copy_level_data_from_temp_to_save()


		if event.is_action_pressed("debug_load"):
			var popup = POPUP.instantiate()
			popup.text = "loaded save"
			w.uig.add_child(popup)
			SaveSystem.read_player_data_from_save()
			SaveSystem.read_level_data_from_save(w.current_level)
			SaveSystem.copy_level_data_from_save_to_temp()

		if event.is_action_pressed("debug_shop"):
			var shop_menu = SHOP_MENU.instantiate()
			w.uig.add_child(shop_menu)


		if event.is_action_pressed("debug_fly"):
			if w.has_node("Juniper"):
				var pc = w.get_node("Juniper")
				if pc.mm.current_state != pc.mm.states["fly"]:
					pc.mm.cached_state = pc.mm.current_state
					pc.mm.change_state("fly")
				else:
					pc.mm.change_state("jump")
					#pc.mm.change_state(pc.mm.cached_state.name.to_lower()) #gave errors


		if event.is_action_pressed("debug_slowmode"):
			if Engine.time_scale != 0.5:
				Engine.time_scale = 0.5
			else:
				Engine.time_scale = 1.0



func debug_print():
	if not w.dl.has_node("DebugInfo"):
		print("showing debug info")
		w.dl.add_child(DEBUG_INFO.instantiate())
	else:
		w.dl.get_node("DebugInfo").queue_free()
#
#
func reload_level():
	print("reloading level")
	if w.ml.has_node("PauseMenu"): w.ml.get_node("PauseMenu").unpause()
	if w.uig.has_node("HUD"): w.uig.get_node("HUD").free()
	w.change_level_via_code(w.current_level.scene_file_path)
