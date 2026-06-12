extends Node

const DEBUG_INFO = preload("res://src/UI/DebugInfo/DebugInfo.tscn")
const WIND_VISUAL = preload("res://src/UI/WindVisual.tscn")
const LEVEL_EDITOR = preload("res://src/Editor/Editor.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")
const SHOP_MENU = preload("res://src/UI/ShopMenu/ShopMenu.tscn")

@onready var w = get_tree().get_root().get_node("World")

var editor_tab = 0 #to save when we re-enter the editor
var time_scales = [
	0.01,
	0.025,
	0.05,
	0.1,
	0.25,
	0.5,
	1.0,
	1.25,
	1.5,
	1.75,
	2.0,
	5.0,
	10.0]
var current_time_scale_index := 6

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("debug_editor") && !w.ml.has_node("TitleScreen") && !w.ml.has_node("PauseMenu"):
		if w.el.has_node("Editor"):
			editor_tab = w.el.get_node("Editor/Main/Win/Tab").current_tab
			w.el.get_node("Editor").exit()
		else:
			print("showing level editor")
			w.el.add_child(LEVEL_EDITOR.instantiate())
			w.el.get_node("Editor/Main/Win/Tab").current_tab = editor_tab
			w.el.get_node("Editor").on_tab_changed(editor_tab)

	if event.is_action_pressed("debug_print"):
		if w.el.has_node("Editor"): return
		debug_print()

	if event.is_action_pressed("debug_wind"):
		if w.el.has_node("Editor"): return
		debug_wind()

	if event.is_action_pressed("debug_reload"):
		if w.el.has_node("Editor"): return
		if f.db():
			await f.db().exit()
		reload_level()


	if event.is_action_pressed("debug_triggers"):
		w.set_debug_visible()


	if event.is_action_pressed("debug_quit"):
		print("quitting...")
		get_tree().quit()

	if not w.el.has_node("Editor"): #non-editor only commands

		if event.is_action_pressed("debug_save"):
			print("debug save")
			var popup = POPUP.instantiate()
			popup.text = "quicksaved..."
			w.ui.add_child(popup)
			SaveSystem.write_mission_data_to_save()
			SaveSystem.write_player_data_to_save(w.current_level)
			SaveSystem.write_level_data_to_temp(w.current_level)
			SaveSystem.copy_level_and_dialog_data_from_temp_to_save()


		if event.is_action_pressed("debug_load"):
			print("debug load")
			var popup = POPUP.instantiate()
			popup.text = "loaded save"
			w.ui.add_child(popup)
			SaveSystem.read_player_data_from_save()
			SaveSystem.read_level_data_from_save(w.current_level)
			SaveSystem.read_dialog_data_from_save(w.current_level)
			SaveSystem.copy_level_and_dialog_data_from_save_to_temp()
			SaveSystem.read_mission_data_from_save()


		if event.is_action_pressed("debug_fly"):
			if f.pc():
				var pc = f.pc()
				if pc.mm.current_state != pc.mm.states["fly"]:
					pc.mm.cached_state = pc.mm.current_state
					pc.mm.change_state("fly")
				else:
					pc.mm.change_state("jump")
					#pc.mm.change_state(pc.mm.cached_state.name.to_lower()) #gave errors

		if event.is_action_pressed("debug_killbind"):
			if f.pc():
				var pc = f.pc()
				if !pc.die_from_falling or pc.mm.current_state == pc.mm.states["fly"]:
					return
				pc.die()

		if event.is_action_pressed("debug_slow_down"):
			if current_time_scale_index != 0:
				current_time_scale_index -= 1
				Engine.time_scale = time_scales[current_time_scale_index]
				print("Time Scale: ", Engine.time_scale)

		if event.is_action_pressed("debug_speed_up"):
			if current_time_scale_index != 12:
				current_time_scale_index += 1
				Engine.time_scale = time_scales[current_time_scale_index]
				print("Time Scale: ", Engine.time_scale)



func debug_print():
	if not w.dl.has_node("DebugInfo"):
		print("showing debug info")
		w.dl.add_child(DEBUG_INFO.instantiate())
	else:
		w.dl.get_node("DebugInfo").queue_free()

func debug_wind():
	if !w.dl.has_node("WindVisual"):
		print("showing wind visual")
		w.dl.add_child(WIND_VISUAL.instantiate())
	else:
		w.dl.get_node("WindVisual").queue_free()

func reload_level():
	print("reloading level")
	w.change_level_via_code(w.current_level.scene_file_path, false)
	current_time_scale_index = 6
	Engine.time_scale = time_scales[current_time_scale_index]
