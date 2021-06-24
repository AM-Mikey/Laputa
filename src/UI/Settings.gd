extends Control
onready var display_mode = $MarginContainer/VBoxContainer/DisplayMode
onready var resolution_scale = $MarginContainer/VBoxContainer/ResolutionScale

onready var master_label = $MarginContainer/VBoxContainer/MasterLabel
onready var music_label = $MarginContainer/VBoxContainer/HBoxContainer/MusicLabel
onready var sfx_label = $MarginContainer/VBoxContainer/HBoxContainer/SFXLabel

onready var world = get_tree().get_root().get_node("World")

func _ready():
	display_mode.add_item("Windowed")
	display_mode.add_item("Borderless")
	display_mode.add_item("Fullscreen")

	resolution_scale.add_item("Auto", 0)
	resolution_scale.add_item("1x", 1)
	resolution_scale.add_item("2x", 2)
	resolution_scale.add_item("3x", 3)
	resolution_scale.add_item("4x", 4)


func _on_DisplayMode_item_selected(index):
	print("display settings changed")
	
	if index == 0:
		ProjectSettings.set_setting("display/window/size/borderless", false)
		ProjectSettings.set_setting("display/window/size/fullscreen", false)
	if index == 1:
		ProjectSettings.set_setting("display/window/size/borderless", true)
		ProjectSettings.set_setting("display/window/size/fullscreen", false)
	if index == 2:
		ProjectSettings.set_setting("display/window/size/borderless", false)
		ProjectSettings.set_setting("display/window/size/fullscreen", true)

	ProjectSettings.save()
	
func _on_ResolutionScale_item_selected(index):
	if index == 0:
		world.viewport_size_ignore = false
		world._on_viewport_size_changed()
	if index == 1:
		world.resolution_scale = 1.0
		world.viewport_size_ignore = true
	if index == 2:
		world.resolution_scale = 2.0
		world.viewport_size_ignore = true
	if index == 3:
		world.resolution_scale = 3.0
		world.viewport_size_ignore = true
	if index == 4:
		world.resolution_scale = 4.0
		world.viewport_size_ignore = true
	
	world.get_node("Recruit").get_node("Camera2D").zoom = Vector2(1 / world.resolution_scale, 1 / world.resolution_scale)
	world.get_node("UILayer").scale = Vector2(world.resolution_scale, world.resolution_scale)



func _on_PixelSnap_toggled(button_pressed):
	ProjectSettings.set_setting("rendering/quality/2d/use_pixel_snap", button_pressed)


func _on_Reset_pressed():
	pass # Replace with function body.


func _on_Save_pressed():
	queue_free()



func _on_MasterSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),db)
	if value == 0:
		master_label.text = "Master Volume: Muted"
	else:
		master_label.text = "Master Volume: " + str(value) + "0 '/."

func _on_MusicSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),db)
	if value == 0:
		music_label.text = "Music Volume: Muted"
	else:
		music_label.text = "Music Volume: " + str(value) + "0 '/."

func _on_SFXSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),db)
	if value == 0:
		sfx_label.text = "SFX Volume: Muted"
	else:
		sfx_label.text = "SFX Volume: " + str(value) + "0 '/."

func percent_to_db(value) -> float:
	var db: float
	
	if value == 0:
		db = -80
	elif value == 1:
		db = -20
	elif value == 2:
		db = -13.9794
	elif value == 3:
		db = -10.4576
	elif value == 4:
		db = -7.9588
	elif value == 5:
		db = -6.0206
	elif value == 6:
		db = -4.4370 
	elif value == 7:
		db = -3.0980
	elif value == 8:
		db = -1.9382 
	elif value == 9:
		db = -0.9151
	elif value == 10:
		db = 0
	elif value == 11:
		db = 0.8279 
	elif value == 12:
		db = 1.5836 
	elif value == 13:
		db = 2.2789
	elif value == 14:
		db = 2.9226
	elif value == 15:
		db = 3.5218
	elif value == 16:
		db = 4.0824
	elif value == 17:
		db = 4.6090
	elif value == 18:
		db = 5.1055
	elif value == 19:
		db = 5.5751 
	elif value == 20:
		db = 6.0206
	else:
		db = 0
	
	return db


