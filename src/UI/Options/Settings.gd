extends Control

var settings_path = "user://settings.json"

#onready var display_mode = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/DisplayMode/OptionButton
#onready var resolution_scale = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/ResolutionScale/OptionButton

var after_ready = false

export(NodePath) var p_master
onready var s_master = get_node(p_master)
export(NodePath) var p_sfx
onready var sfx = get_node(p_sfx)
export(NodePath) var p_music
onready var music = get_node(p_music)

export(NodePath) var display_b
export(NodePath) var resolution_b
export(NodePath) var mouse_b
export(NodePath) var delete_b

export(NodePath) var scroll_c
#var scroll_size = 

onready var world = get_tree().get_root().get_node("World")

var default = {
	"DisplayMode": 0,
	"ResolutionScale": 0,
	"MasterSlider": 10.0,
	"MusicSlider": 0.0,
	"SFXSlider" : 10.0
	}

func _ready():
	var file = File.new()
	if not file.file_exists(settings_path):
		save_defaults()
	else: 
		load_settings()
	get_node(scroll_c).get_v_scrollbar().connect("item_rect_changed", self, "_on_scrollbar_changed")
	after_ready = true


func _on_scrollbar_changed():
	print("scroll changed")
	get_node(scroll_c).get_v_scrollbar().rect_size.y = get_node(scroll_c).rect_size.y - 48

func load_settings():
	var data
	
	var file = File.new()
	if file.file_exists(settings_path):
		var file_read = file.open(settings_path, File.READ)
		if file_read == OK:
			var text = file.get_as_text()
			data = JSON.parse(text).result
			file.close()

		get_node(display_b).selected = data["DisplayMode"]
		_on_DisplayMode_item_selected(data["DisplayMode"])
		get_node(resolution_b).selected = data["ResolutionScale"]
		_on_ResolutionScale_item_selected(data["ResolutionScale"])
		
		
		s_master.get_node("Slider").value = data["MasterSlider"]
		_on_MasterSlider_value_changed(data["MasterSlider"])
		music.get_node("Slider").value = data["MusicSlider"]
		_on_MusicSlider_value_changed(data["MusicSlider"])
		sfx.get_node("Slider").value = data["SFXSlider"]
		_on_SFXSlider_value_changed(data["SFXSlider"])

	else: 
		printerr("ERROR: could not load settings data")
	

func _on_DisplayMode_item_selected(index):
	print("display settings changed")
	
	if index == 0: #windowed
		OS.set_borderless_window(false)
		OS.set_window_fullscreen(false)
		
#		OS.set_window_size(OS.get_window_size()) #set window size so we can trigger _on_viewport_size_changed everywhere
		
	if index == 1: #borderless
		OS.set_window_fullscreen(false)
		OS.set_window_size(OS.get_screen_size())
		OS.set_window_position(Vector2.ZERO)
		OS.set_borderless_window(true)
		
	if index == 2: #fullscreen
		OS.set_borderless_window(false)
		OS.set_window_fullscreen(true)
	
	save_to_file("DisplayMode", index)

func _on_ResolutionScale_item_selected(index):

	if index == 0:
		world.viewport_size_ignore = false
		#world._on_viewport_size_changed()
		OS.set_window_size(OS.get_window_size()) #set window size so we can trigger _on_viewport_size_changed everywhere
		
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
	
	if world.has_node("TitleCam"):
		world.get_node("TitleCam").zoom = Vector2(1 / world.resolution_scale, 1 / world.resolution_scale)
	#world.get_node("UILayer").scale = Vector2(world.resolution_scale, world.resolution_scale)
	#TODO: make sure this carrys over for playercamera
	
	if get_tree().get_nodes_in_group("CameraLimiters").size() != 0:
		for c in get_tree().get_nodes_in_group("CameraLimiters"):
			c._on_viewport_size_changed()
	
	save_to_file("ResolutionScale", index)


func _on_Reset_pressed():
	save_defaults()


func _on_Return_pressed():
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").visible = true
		world.get_node("UILayer/PauseMenu").focus()
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").visible = true
		world.get_node("UILayer/TitleScreen").focus()
		
	if world.has_node("UILayer/Options"):
		world.get_node("UILayer/Options").queue_free()
	else:
		get_parent().queue_free()



func _on_MasterSlider_value_changed(value):
	var db = percent_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),db)
	if not world.get_node("UILayer/Options").hidden and after_ready:
		am.play_master("sound_test")
	s_master.get_node("Label").text = "Master Volume: Muted" if value == 0 else "Master Volume: " + str(value) + "0 %"
	save_to_file("MasterSlider", value)

func _on_MusicSlider_value_changed(value):
	var db = percent_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),db)
	if not world.get_node("UILayer/Options").hidden and after_ready:
		am.play_music("sound_test")
	music.get_node("Label").text = "Music Volume: Muted" if value == 0 else "Music Volume: " + str(value) + "0 %"
	save_to_file("MusicSlider", value)

func _on_SFXSlider_value_changed(value):
	var db = percent_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),db)
	if not world.get_node("UILayer/Options").hidden and after_ready:
		am.play("sound_test")
	sfx.get_node("Label").text = "SFX Volume: Muted" if value == 0 else "SFX Volume: " + str(value) + "0 %"
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

func _on_MouseLock_toggled(value):
	if value:
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_DeleteSave_pressed():
	var files = []
	var dir = Directory.new()
	dir.open("user://")
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	
	
	for f in files:
		if f.get_extension() == "dat" or f.get_extension() == "json":
			dir.remove("user://%s" % f)
			print("removed file: " + "user://%s" % f)
	
	$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/DeleteSave/Button.text = "Done"

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





func focus():
	s_master.get_node("Slider").grab_focus()









