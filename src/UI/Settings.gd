extends Control

var settings_path = "user://settings.json"

onready var display_mode = $MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/DisplayMode/OptionButton
onready var resolution_scale = $MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ResolutionScale/OptionButton

onready var master_label = $MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/MasterLabel
onready var music_label = $MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/MusicLabel
onready var sfx_label = $MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/SFXLabel

onready var world = get_tree().get_root().get_node("World")

var default = {
	"DisplayMode": 0,
	"ResolutionScale": 0,
	"MasterSlider": 100,
	"MusicSlider": 100,
	"SFXSlider" : 100
	}

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	
	display_mode.add_item("Windowed")
	display_mode.add_item("Borderless")
	display_mode.add_item("Fullscreen")

	resolution_scale.add_item("Auto", 0)
	resolution_scale.add_item("1x", 1)
	resolution_scale.add_item("2x", 2)
	resolution_scale.add_item("3x", 3)
	resolution_scale.add_item("4x", 4)
	
	var file = File.new()
	if not file.file_exists(settings_path):
		save_defaults()


func _on_DisplayMode_item_selected(index):
	print("display settings changed")
	
	if index == 0: #windowed
		OS.set_borderless_window(false)
		OS.set_window_fullscreen(false)
	if index == 1: #borderless
		OS.set_borderless_window(true)
		OS.set_window_fullscreen(false)
	if index == 2: #fullscreen
		OS.set_borderless_window(false)
		OS.set_window_fullscreen(true)
		
	save_to_file("DisplayMode", index)

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
	
	if get_tree().get_nodes_in_group("CameraLimiters").size() != 0:
		for c in get_tree().get_nodes_in_group("CameraLimiters"):
			c._on_viewport_size_changed()
	_on_viewport_size_changed() #didnt fix it

	save_to_file("ResolutionScale", index)


func _on_Reset_pressed():
	save_defaults()


func _on_Save_pressed():
	queue_free()



func _on_MasterSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),db)
	if value == 0:
		master_label.text = "Master Volume: Muted"
	else:
		master_label.text = "Master Volume: " + str(value) + "0 '/."
		
		save_to_file("MasterSlider", value)

func _on_MusicSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),db)
	if value == 0:
		music_label.text = "Music Volume: Muted"
	else:
		music_label.text = "Music Volume: " + str(value) + "0 '/."
		
		save_to_file("MusicSlider", value)

func _on_SFXSlider_value_changed(value):
	var db = percent_to_db(value)
	var volume = AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),db)
	if value == 0:
		sfx_label.text = "SFX Volume: Muted"
	else:
		sfx_label.text = "SFX Volume: " + str(value) + "0 '/."

	save_to_file("SFXSlider", value)
	
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

func _on_DeleteSave_pressed():
	var dir = Directory.new()
	dir.remove("user://config.json")
	dir.remove("user://settings.json")
	dir.remove("user://save.dat")
	dir.remove("user://temp.dat")
	$MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/DeleteSave/Button.text = "Done"

func save_defaults():
	var data = default
	
	var file = File.new()
	var file_written = file.open(settings_path, File.WRITE)
	if file_written == OK:
		file.store_string(var2str(data))
		file.close()
		print("default settings data saved")
	else:
		printerr("ERROR: default settings data could not be saved!")

func save_to_file(setting, setting_value):

	var data = default
	data[setting] = setting_value
	
	var file = File.new()
	var file_written = file.open(settings_path, File.WRITE)
	if file_written == OK:
		file.store_string(var2str(data))
		file.close()
		print("settings data saved")
	else:
		printerr("ERROR: settings data could not be saved!")












func _on_viewport_size_changed():
	$MarginContainer.rect_size = get_tree().get_root().size / world.resolution_scale



