extends MarginContainer

const JUNIPER = preload("res://src/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const LEVEL_BUTTON = preload("res://src/Editor/Button/LevelButton.tscn")

signal level_selected(level_path) #never used

const LEVEL_DIR = "res://src/Level/"
const DEFAULT_LEVEL = "res://src/Level/Default.tscn" #template for new levels, editor_hidden

var levels = {}
var active_level_path

@onready var w = get_tree().get_root().get_node("World")
@onready var editor = get_parent().get_parent().get_parent().get_parent()


func setup_levels(select_path := ""):
	for c in %ButtonsNone.get_children(): c.queue_free()
	for c in %ButtonsEnemyDebug.get_children(): c.queue_free()

	var index = 0
	for l in find_level_scenes(LEVEL_DIR):
		var level_button = create_button(l)
		if level_button == null: #editor_hidden levels
			continue
		if (select_path == "" and index == 0) or l == select_path:
			level_button.active = true
			active_level_path = l
		%ButtonsNone.add_child(level_button)
		index += 1

	for l in find_level_scenes(LEVEL_DIR + "EnemyDebug/"):
		var level_button = create_button(l)
		if level_button == null:
			continue
		%ButtonsEnemyDebug.add_child(level_button)


func get_root_property(scene: PackedScene, prop: StringName, default = null) -> Variant:
	var state := scene.get_state()
	for i in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == prop:
			return state.get_node_property_value(0, i)
	return default


func find_level_scenes(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".tscn"):
			files.append(path + file)
	return files

func create_button(path):
	var level_scene: PackedScene = load(path) #never gets instantiated, just reading
	if get_root_property(level_scene, &"editor_hidden", false):
		return
	var level_name = get_root_property(level_scene, &"level_name", "")
	levels[level_name] = level_scene

	var level_button = LEVEL_BUTTON.instantiate()
	level_button.level_path = path
	level_button.level_name = level_name
	level_button.connect("level_selected", Callable(self, "_on_level_selected"))
	return level_button



### SAVE/LOAD ###

func save_level(level, path):
	var e_log = editor.e_log
	editor.inspector.on_deselected()
	level.save_changes()
	level.name = path.get_file().get_basename()
	level.level_name = path.get_file().get_basename() #TODO: add this to inspector
	if FileAccess.file_exists(path):
		e_log.lprint("Saved over File")
		print("Saved over File")

	var packed_scene = PackedScene.new()
	packed_scene.pack(level)
	var err = ResourceSaver.save(packed_scene, path)

	if err == OK:
		e_log.lprint(str("Saved Level to:", path))
		print("Saved Level to: ", path)
		am.play("save")
	else:
		e_log.lprint("ERROR: Could Not Save File")
		printerr("ERROR: Could Not Save File")


func load_level(path):
	if f.pc: f.pc().free()
	if f.hud(): f.hud().free()
	if w.ml.has_node("Title"): w.ml.get_node("Title").queue_free()
	if w.ml.has_node("PauseMenu"): w.ml.get_node("PauseMenu").exit()
	w.el.get_node("Editor").inspector.on_deselected()

	w.change_level_via_code(path, true)
	await get_tree().process_frame
	w.el.get_node("Editor").enter()
	w.el.get_node("EditorCamera").enabled = true
	w.el.get_node("EditorCamera").global_position = f.pc().global_position



### BUTTON SIGNALS ###

func _on_level_selected(path): #connected to level buttons
	active_level_path = path

func on_save(): #from editor
	save_level(w.current_level, w.current_level.scene_file_path)

func on_save_as():
	$SaveDialog.current_dir = LEVEL_DIR
	$SaveDialog.popup()

func on_load():
	for kb in get_tree().get_nodes_in_group("KillBoxes"):
		kb.forbid = true
	load_level(active_level_path)
	#$LoadDiae_log.current_path = "res://src/level/"
	#$LoadDiae_log.popup()

func on_new():
	$NewDialog.current_dir = LEVEL_DIR
	$NewDialog.current_file = ""
	$NewDialog.popup()

func _on_Default_pressed():
	w.start_level_path = w.current_level.scene_file_path
	var packed_scene = PackedScene.new()
	packed_scene.pack(w) #packing world is a bad idea, we need to be sure nothing else gets saved along with default level
	var err = ResourceSaver.save(packed_scene, "res://src/World.tscn")

	if err == OK:
		print("Saved Default Level as: " + w.current_level.scene_file_path)
		am.play("save")
	else: printerr("ERROR: Could Not Save Default Level")



### DIALOG SIGNALS

func on_save_confirmed():
	var level = w.current_level
	var path = $SaveDialog.current_path.get_basename() + ".tscn"
	save_level(level, path)

#func on_load_selected(path):
	#load_level(path)

func on_new_selected(path: String): #connected to NewDialog file_selected
	var level_name = path.get_file().get_basename()
	if not level_name.is_valid_ascii_identifier(): #root node name must be valid, and keeps file names consistent
		editor.e_log.lprint(str("ERROR: Invalid level name \"", level_name, "\". Use only letters, numbers and _, not starting with a number"))
		printerr("ERROR: Invalid level name: ", level_name)
		return
	path = path.get_base_dir().path_join(level_name + ".tscn")

	var level = load(DEFAULT_LEVEL).instantiate()
	level.editor_hidden = false #template is hidden, new level should not be
	save_level(level, path)
	level.free()

	setup_levels(path)
	load_level(path)
