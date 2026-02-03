extends Control

const KEY_GUIDE = preload("res://src/UI/KeyGuide.tscn")
const LEVELSELECT = preload("res://src/UI/LevelSelect/LevelSelect.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")

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
	if f.hud():
		f.hud().free()
	do_focus()
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


func do_focus():
	print("focusing on title screen")
	if $VBox.has_node("Load"):
		$VBox/Load.grab_focus()
	else:
		$VBox/New.grab_focus()

func exit():
	get_tree().paused = false
	w.ui.visible = true
	w.hl.visible = true
	queue_free()
	var camera = get_viewport().get_camera_2d()
	if camera:
		if camera.is_in_group("PlayerCameras"):
			camera.reset()

### SIGNALS ###

func _on_new():
	w.change_level_via_code(w.start_level_path, false)
	exit()


func _on_load():
	SaveSystem.read_player_data_from_save()
	SaveSystem.read_level_data_from_save(w.current_level)
	SaveSystem.copy_level_data_from_save_to_temp()
	SaveSystem.read_mission_data_from_save()
	exit()

func _on_options():
	get_parent().add_child(OPTIONS.instantiate())

func _on_level():
	get_parent().add_child(LEVELSELECT.instantiate())

func _on_quit():
	get_tree().quit()

func _on_keyguide():
	get_parent().add_child(KEY_GUIDE.instantiate())

func _resolution_scale_changed(_resolution_scale):
	set_deferred("size", get_tree().get_root().size / vs.menu_resolution_scale)
