extends MarginContainer

const JUNIPER = preload("res://src/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const TITLESCREEN = preload("res://src/UI/TitleScreen.tscn")


@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node("World/Juniper")
@onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

func _ready():
	visible = false
	#w.get_node("MusicPlayer").stop()
	am.play("pc_die")
	hud.visible = false
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	
	#TODO: wait and fix camera
	do_focus()
	visible = true
	am.play_music("gameover")
	$AnimationPlayer.play("In")
	#w.get_node("DeathCam").focus_player()


func do_focus():
	#print("focused")
	$VBox/HBox/Continue.grab_focus()

func _on_Continue_pressed():
	visible = false
	w.get_node("DeathCamera").queue_free()

	SaveSystem.read_player_data_from_save()
	SaveSystem.read_level_data_from_save(w.current_level)
	SaveSystem.copy_level_data_from_save_to_temp()
	
	queue_free()


func _on_Quit_pressed():
	visible = false
	w.get_node("UILayer").add_child(TITLESCREEN.instantiate())
	

func on_viewport_size_changed():
	size = get_tree().get_root().size / w.resolution_scale
