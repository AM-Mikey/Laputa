extends MarginContainer

const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const TITLESCREEN = preload("res://src/UI/TitleScreen.tscn")


onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Juniper")
onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

func _ready():
	visible = false
	#world.get_node("MusicPlayer").stop()
	am.play("pc_die")
	hud.visible = false
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()
	
	#TODO: wait and fix camera
	focus()
	visible = true
	am.play_music("gameover")
	$AnimationPlayer.play("In")
	#world.get_node("DeathCam").focus_player()


func focus():
	print("focused")
	$VBox/HBox/Continue.grab_focus()

func _on_Continue_pressed():
	visible = false
	
	
	world.add_child(JUNIPER.instance())
	world.get_node("UILayer").add_child(HUD.instance())
	
	world.read_player_data_from_save()
	world.read_level_data_from_save()
	world.copy_level_data_from_save_to_temp()
	
	
	#world.get_node("DeathCam").queue_free()
	queue_free()
	


func _on_Quit_pressed():
	visible = false
	world.get_node("UILayer").add_child(TITLESCREEN.instance())
	

func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale


