extends MarginContainer

const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")

onready var w = get_tree().get_root().get_node("World")
onready var ui = w.get_node("UILayer")
onready var el = w.get_node("EditorLayer")


func _on_Save_pressed():
	$Save.popup()

func _on_Save_confirmed():
	var path = $Save.current_path.get_basename() + ".tscn"
	var level = w.current_level
	
	level.name = $Save.current_path.get_file().get_basename()
	level.level_name = $Save.current_path.get_file().get_basename()
	
	
	var packed_scene = PackedScene.new()
	packed_scene.pack(level)
	var err = ResourceSaver.save(path, packed_scene)
	
	if err == OK: print("Saved Level to: " + path)
	else: printerr("ERROR: Could Not Save File")


func _on_Load_pressed():
	$Load.popup()

func _on_Load_file_selected(path):
	print(path)
	
	
	if w.has_node("Juniper"):
		w.get_node("Juniper").free() #we free and respawn them so we have a clean slate when we load in
	if ui.has_node("HUD"):
		ui.get_node("HUD").free()
	
	w.on_level_change(load(path), 0)
	
	if ui.has_node("TitleScreen"):
		ui.get_node("TitleScreen").queue_free()
	if ui.has_node("PauseMenu"):
		ui.get_node("PauseMenu").unpause()

	w.add_child(JUNIPER.instance())
	ui.add_child(HUD.instance())
	
	yield(get_tree(), "idle_frame")
	
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		w.get_node("Juniper").global_position = s.global_position
	
	
	el.get_node("EditorCamera").queue_free()
	el.get_node("Editor").queue_free()
	ui.add_child(HUD.instance())
	#w.get_node("Juniper").enable()
	w.get_node("Juniper/PlayerCamera").current = true
