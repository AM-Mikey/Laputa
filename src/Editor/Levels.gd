extends MarginContainer

const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")

var icon = "res://assets/Icon/LevelIcon.png"

onready var w = get_tree().get_root().get_node("World")
onready var ui = w.get_node("UILayer")
onready var el = w.get_node("EditorLayer")

var ctrl_held := false

func _unhandled_input(event):
	if event.is_action_pressed("editor_ctrl"): ctrl_held = true

### BUTTON SIGNALS

func on_save():
	save_level(w.current_level, w.current_level.filename)

func on_save_as():
	$SaveDialog.current_path = "res://src/level/"
	$SaveDialog.popup()

func on_load():
	$LoadDialog.current_path = "res://src/level/"
	$LoadDialog.popup()


### DIALOG SIGNALS

func on_save_confirmed():
	var level = w.current_level
	var path = $SaveDialog.current_path.get_basename() + ".tscn"
	save_level(level, path)

func on_load_selected(path):
	load_level(path)

### SAVE/LOAD

func save_level(level, path):
	level.name = path.get_file().get_basename()
	level.level_name = path.get_file().get_basename() #TODO: add this to inspector
	
	var dir = Directory.new()
	if dir.file_exists(path):
		print("WARNING: Saved over File!")
		
	var packed_scene = PackedScene.new()
	packed_scene.pack(level)
	var err = ResourceSaver.save(path, packed_scene)
	
	if err == OK:
		print("Saved Level to: " + path)
		am.play("save")
	else: printerr("ERROR: Could Not Save File")


func load_level(path):
	if w.has_node("Juniper"): w.get_node("Juniper").free() #we free and respawn them so we have a clean slate when we load in
	if ui.has_node("HUD"): ui.get_node("HUD").free()
	if ui.has_node("TitleScreen"): ui.get_node("TitleScreen").queue_free()
	if ui.has_node("PauseMenu"): ui.get_node("PauseMenu").unpause()
	
	el.get_node("Editor").inspector.on_deselected()
	
	w.on_level_change(load(path), 0)

	w.add_child(JUNIPER.instance())
	ui.add_child(HUD.instance())
	
	yield(get_tree(), "idle_frame")
	
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		w.get_node("Juniper").global_position = s.global_position

	el.get_node("Editor").setup_level()
	el.get_node("EditorCamera").current = true
