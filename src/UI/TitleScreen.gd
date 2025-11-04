extends Control

const KEY_GUIDE = preload("res://src/UI/KeyGuide.tscn")
const LEVELSELECT = preload("res://src/UI/LevelSelect/LevelSelect.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")
const JUNIPER = preload("res://src/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")

@onready var w = get_tree().get_root().get_node("World")



func _ready():
	#VERSION STUFF
	if w.is_release:
		$VersionLabel.text = "Release Version: " + w.development_stage + "-" + w.release_version
	else:
		$VersionLabel.text = "Internal Version: " + w.development_stage + "-" + w.internal_version
										#LOAD BUTTON STUFF
	if not FileAccess.file_exists(SaveSystem.save_path):
		$VBox/Load.queue_free()

	####
	am.play_music("theme")
	await get_tree().process_frame
	do_focus()
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


func do_focus():
	print("focusing on title screen")
	if $VBox.has_node("Load"):
		$VBox/Load.grab_focus()
	else:
		$VBox/New.grab_focus()



### SIGNALS ###

func _on_new():
	queue_free()

	w.on_level_change(w.start_level.scence_file_path, -1)
	w.add_child(JUNIPER.instantiate())
	w.get_node("UILayer/UIGroup").add_child(HUD.instantiate())

	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		w.get_node("Juniper").position = s.global_position

func _on_load():
	queue_free()
	SaveSystem.read_player_data_from_save()
	SaveSystem.read_level_data_from_save(w.current_level)
	SaveSystem.copy_level_data_from_save_to_temp()

func _on_options():
	get_parent().add_child(OPTIONS.instantiate())

func _on_level():
	get_parent().add_child(LEVELSELECT.instantiate())

func _on_quit():
	get_tree().quit()

func _on_keyguide():
	get_parent().add_child(KEY_GUIDE.instantiate())

func _resolution_scale_changed(_resolution_scale):
	size = get_tree().get_root().size / vs.menu_resolution_scale
