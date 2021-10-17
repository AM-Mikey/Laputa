extends MarginContainer

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
	focus()
	visible = true
	world.get_node("MusicPlayer").stream = music_gameover
	world.get_node("MusicPlayer").play()
	$AnimationPlayer.play("In")

func focus():
	print("focused")
	$VBox/HBox/Continue.grab_focus()

func _on_Continue_pressed():
	visible = false
	pc.disabled = false
	pc.visible = true
	hud.visible = true
	world.load_player_data_from_save()
	world.load_level_data_from_save()
	world.copy_level_data_to_temp()


func _on_Quit_pressed():
	get_tree().quit()

func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale


