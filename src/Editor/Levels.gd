extends MarginContainer

const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const LEVEL_BUTTON = preload("res://src/Editor/Button/LevelButton.tscn")

signal level_changed(level_path)

var levels = {}
var active_level_path
var default_level = "res://src/Level/Default.tscn"

@onready var w = get_tree().get_root().get_node("World")
@onready var ui = w.get_node("UILayer")
@onready var el = w.get_node("EditorLayer")

@onready var editor = get_parent().get_parent().get_parent().get_parent()



func _ready():
	setup_levels()

func setup_levels(): #TODO: connect this to editor instead of _ready
	editor.connect("tab_changed", Callable(self, "on_tab_changed"))
	var index = 0
	for l in find_level_scenes("res://src/Level/"):
		
		var level = load(l).instantiate()
		if not level.editor_hidden:
			levels[level.name] = level
			
			var level_button = LEVEL_BUTTON.instantiate()
			level_button.level_path = l
			level_button.level_name = level.name
			level_button.connect("level_changed", Callable(self, "change_level"))
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

func change_level(path): #connected to level buttons
	load_level(path)

### BUTTON SIGNALS

func on_save(): #from editor
	save_level(w.current_level, w.current_level.scene_file_path)

func on_save_as():
	$SaveDialog.current_path = "res://src/level/"
	$SaveDialog.popup()

func on_load():
	$LoadDialog.current_path = "res://src/level/"
	$LoadDialog.popup()

func on_new():
	$NewDialog.current_path = "res://src/level/"
	$NewDialog.popup()

func _on_Default_pressed():
	w.start_level = load(w.current_level.scene_file_path)
	#am.play("save")


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

func on_load_selected(path):
	load_level(path)

func on_new_confirmed():
	var level = load(default_level).instantiate()
	var path = $NewDialog.current_path.get_basename() + ".tscn"
	save_level(level, path)
	load_level(path)


### SAVE/LOAD

func save_level(level, path):
	var log = el.get_node("Editor").log
	el.get_node("Editor").inspector.on_deselected()
	
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
	if w.has_node("Juniper"): w.get_node("Juniper").free() #we free and respawn them so we have a clean slate when we load in
	if ui.has_node("HUD"): ui.get_node("HUD").free()
	if ui.has_node("TitleScreen"): ui.get_node("TitleScreen").queue_free()
	if ui.has_node("PauseMenu"): ui.get_node("PauseMenu").unpause()
	
	el.get_node("Editor").inspector.on_deselected()
	
	w.on_level_change(path, 0)

	w.add_child(JUNIPER.instantiate())
	ui.add_child(HUD.instantiate())
	
	await get_tree().process_frame
	
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		w.get_node("Juniper").global_position = s.global_position

	el.get_node("Editor").setup_level()
	el.get_node("EditorCamera").current = true



### SIGNALS ###

func on_tab_changed(tab_name):
	pass
