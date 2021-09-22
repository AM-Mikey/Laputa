extends Control

const LEVELSELECT = preload("res://src/UI/LevelSelect.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")

onready var world = get_tree().get_root().get_node("World")
onready var player = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")


func _ready():
	get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	

												#VERSION STUFF
	if world.is_release:
		$VersionLabel.text = "Release Version: " + world.development_stage + "-" + world.release_version
	else:
		$VersionLabel.text = "Internal Version: " + world.development_stage + "-" + world.internal_version
	
										#LOAD BUTTON STUFF
	var file = File.new()
	if not file.file_exists(world.save_path):
		$VBoxContainer/Load.queue_free()
	
	
	
	yield(get_tree(), "idle_frame")
	on_viewport_size_changed()
	focus()
	

func _on_New_pressed():
	visible = false
	queue_free()
	
	world.on_level_change(world.starting_level, 0, "LevelSelect", "res://assets/Music/XXXX.ogg")
	world.get_node("Recruit").visible = true
	world.get_node("Recruit").disabled = false
	world.get_node("UILayer/HUD").visible = true
	
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		world.get_node("Recruit").position = s.global_position


func _on_Load_pressed():
	visible = false
	player.disabled = false
	player.visible = true
	hud.visible = true
	world.load_player_data_from_save()
	world.load_level_data_from_save()
	world.copy_level_data_to_temp()


func _on_Options_pressed():
	get_parent().add_child(OPTIONS.instance())


func _on_Level_pressed():
	get_parent().add_child(LEVELSELECT.instance())


func _on_Quit_pressed():
	get_tree().quit()


func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale


func focus():
	print("focusing on title screen")
	if $VBoxContainer.has_node("Load"):
		$VBoxContainer/Load.grab_focus()
	else:
		$VBoxContainer/New.grab_focus()
