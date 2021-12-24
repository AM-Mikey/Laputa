extends MarginContainer

const RECRUIT = preload("res://src/Actor/Player/Recruit.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const TITLESCREEN = preload("res://src/UI/TitleScreen.tscn")

var music_gameover = preload("res://assets/SFX/Placeholder/Gameover.mp3")

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")
onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

func _ready():
	visible = false
	world.get_node("MusicPlayer").stop()
	$DeathSound.play()
	hud.visible = false
	get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()

func _on_DeathSound_finished():
	world.in_menu = true
	focus()
	visible = true
	world.get_node("MusicPlayer").stream = music_gameover
	world.get_node("MusicPlayer").play()
	$AnimationPlayer.play("In")
	world.get_node("DeathCam").focus_player()

func focus():
	print("focused")
	$VBox/HBox/Continue.grab_focus()

func _on_Continue_pressed():
	visible = false
	
	
	world.add_child(RECRUIT.instance())
	world.get_node("UILayer").add_child(HUD.instance())
	
	world.load_player_data_from_save()
	world.load_level_data_from_save()
	world.copy_level_data_to_temp()
	
	
	world.get_node("DeathCam").queue_free()
	queue_free()
	


func _on_Quit_pressed():
	visible = false
	world.get_node("UILayer").add_child(TITLESCREEN.instance())
	

func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale


