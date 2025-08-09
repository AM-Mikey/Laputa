extends Control

const KEY_GUIDE = preload("res://src/UI/KeyGuide.tscn")
const LEVELSELECT = preload("res://src/UI/LevelSelect/LevelSelect.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")
const JUNIPER = preload("res://src/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")

@onready var w = get_tree().get_root().get_node("World")



func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	
												#VERSION STUFF
	if w.is_release:
		$VersionLabel.text = "Release Version: " + w.development_stage + "-" + w.release_version
	else:
		$VersionLabel.text = "Internal Version: " + w.development_stage + "-" + w.internal_version
										#LOAD BUTTON STUFF
	if not FileAccess.file_exists(w.save_path):
		$VBox/Load.queue_free()
	
	
	####
	am.play_music("theme")
	
	await get_tree().process_frame
	on_viewport_size_changed()
	do_focus()



func _on_new():
	queue_free()
	
	w.on_level_change(w.start_level.scence_file_path, -1)
	w.add_child(JUNIPER.instantiate())
	w.get_node("UILayer").add_child(HUD.instantiate())
	
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		w.get_node("Juniper").position = s.global_position


func _on_load():
	queue_free()
	
	w.add_child(JUNIPER.instantiate())
	w.get_node("UILayer").add_child(HUD.instantiate())
	w.read_player_data_from_save()
	w.read_level_data_from_save()
	w.copy_level_data_from_save_to_temp()


func _on_options():
	get_parent().add_child(OPTIONS.instantiate())


func _on_level():
	get_parent().add_child(LEVELSELECT.instantiate())


func _on_quit():
	get_tree().quit()

func _on_keyguide():
	get_parent().add_child(KEY_GUIDE.instantiate())
	

func do_focus():
	print("focusing on title screen")
	if $VBox.has_node("Load"):
		$VBox/Load.grab_focus()
	else:
		$VBox/New.grab_focus()

func on_viewport_size_changed():
	size = get_tree().get_root().size / w.resolution_scale
