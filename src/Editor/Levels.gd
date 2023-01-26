extends MarginContainer

const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const LEVEL_BUTTON = preload("res://src/Editor/Button/LevelButton.tscn")

signal level_changed(level_path)

var levels = {}
var active_level_path
var default_level = "res://src/Level/Default.tscn"
var ctrl_held := false

onready var w = get_tree().get_root().get_node("World")
onready var ui = w.get_node("UILayer")
onready var el = w.get_node("EditorLayer")

func _unhandled_input(event):
	if event.is_action_pressed("editor_ctrl"): ctrl_held = true





func _ready():
	setup_enemies()


func setup_enemies():
	var index = 0
	for l in find_level_scenes("res://src/Level/"):
		
		var level = load(l).instance()
		if not level.editor_hidden:
			levels[level.name] = level
			
			var level_button = LEVEL_BUTTON.instance()
			level_button.level_path = l
			level_button.level_name = level.name
			level_button.connect("level_changed", self, "change_level")
			if index == 0:
				level_button.active = true
				active_level_path = l
			$VBox/Margin/Scroll/Buttons.add_child(level_button)
			index += 1

func find_level_scenes(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)

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

func on_save():
	save_level(w.current_level, w.current_level.filename)

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
	w.start_level = load(w.current_level.filename)
	#am.play("save")


	var packed_scene = PackedScene.new()
	packed_scene.pack(w) #packing world is a bad idea, we need to be sure nothing else gets saved along with default level
	var err = ResourceSaver.save("res://src/World.tscn", packed_scene)
	
	if err == OK:
		print("Saved Default Level as: " + w.current_level.filename)
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
	var level = load(default_level).instance()
	var path = $NewDialog.current_path.get_basename() + ".tscn"
	save_level(level, path)
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



