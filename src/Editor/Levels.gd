extends MarginContainer

const JUNIPER = preload("res://src/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const LEVEL_BUTTON = preload("res://src/Editor/Button/LevelButton.tscn")

signal level_selected(level_path) #never used

var levels = {}
var active_level_path
var default_level = "res://src/Level/Default.tscn"

@onready var w = get_tree().get_root().get_node("World")
@onready var editor = get_parent().get_parent().get_parent().get_parent()

func setup_levels():
	editor.connect("tab_changed", Callable(self, "on_tab_changed"))

	for c in $VBox/Margin/Scroll/Buttons.get_children():
		c.queue_free()

	var index = 0
	for l in find_level_scenes("res://src/Level/"):

		var level = load(l).instantiate()
		if not level.editor_hidden:
			levels[level.name] = level

			var level_button = LEVEL_BUTTON.instantiate()
			level_button.level_path = l
			level_button.level_name = level.name
			level_button.connect("level_selected", Callable(self, "select_level"))
			if index == 0:
				level_button.active = true
				active_level_path = l
			$VBox/Margin/Scroll/Buttons.add_child(level_button)
			index += 1


func find_level_scenes(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".tscn"):
			files.append(path + file)

	return files


### BUTTON SIGNALS

func select_level(path): #connected to level buttons
	active_level_path = path

func on_save(): #from editor
	save_level(w.current_level, w.current_level.scene_file_path)

func on_save_as():
	$SaveDialog.current_path = "res://src/level/"
	$SaveDialog.popup()

func on_load():
	load_level(active_level_path)
	#$LoadDialog.current_path = "res://src/level/"
	#$LoadDialog.popup()

func on_new():
	$NewDialog.current_path = "res://src/level/"
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

func on_new_confirmed():
	var level = load(default_level).instantiate()
	var path = $NewDialog.current_path.get_basename() + ".tscn"
	save_level(level, path)
	load_level(path)


### SAVE/LOAD
func save_level(level, path):
	var log = w.el.get_node("Editor").log
	w.el.get_node("Editor").inspector.on_deselected()

	level.save_changes()
	level.name = path.get_file().get_basename()
	level.level_name = path.get_file().get_basename() #TODO: add this to inspector

	if FileAccess.file_exists(path):
		log.lprint("Saved over File")
		print("Saved over File")

	var packed_scene = PackedScene.new()
	packed_scene.pack(level)
	var err = ResourceSaver.save(packed_scene, path)

	if err == OK:
		log.lprint(str("Saved Level to:", path))
		print("Saved Level to: ", path)
		am.play("save")
	else:
		log.lprint("ERROR: Could Not Save File")
		printerr("ERROR: Could Not Save File")


func load_level(path):
	if w.has_node("Juniper"): w.get_node("Juniper").free()
	if w.uig.has_node("HUD"): w.uig.get_node("HUD").free()
	if w.ml.has_node("TitleScreen"): w.ml.get_node("TitleScreen").queue_free()
	if w.ml.has_node("PauseMenu"): w.ml.get_node("PauseMenu").unpause()
	w.el.get_node("Editor").inspector.on_deselected()

	w.change_level_via_code(path)
	await get_tree().process_frame
	w.el.get_node("Editor").setup_level()
	w.el.get_node("EditorCamera").enabled = true
	w.el.get_node("EditorCamera").global_position = w.get_node("Juniper").global_position



### SIGNALS ###

func on_tab_changed(_tab_name):
	pass
