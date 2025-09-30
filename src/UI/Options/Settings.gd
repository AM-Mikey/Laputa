extends Control

var settings_path = "user://settings.json" #TODO FIX ALL SIGNALS ON ALL BUTTONS

@export var mastervolume_path: NodePath
@export var sfxvolume_path: NodePath
@export var musicvolume_path: NodePath
@export var displaymode_path: NodePath
@export var resolutionscale_path: NodePath
@export var mouselock_path: NodePath
@export var deletesave_path: NodePath
@export var scroll_path: NodePath

var default = {
	"MasterVolume": 10.0,
	"MusicVolume": 0.0,
	"SFXVolume" : 10.0,
	"DisplayMode": 3,
	"ResolutionScale": 0,
	"MouseLock": false,
	}
var after_ready = false

@onready var w = get_tree().get_root().get_node("World")

@onready var mastervolume = get_node(mastervolume_path)
@onready var sfxvolume = get_node(sfxvolume_path)
@onready var musicvolume = get_node(musicvolume_path)
@onready var displaymode = get_node(displaymode_path)
@onready var resolutionscale = get_node(resolutionscale_path)
@onready var mouselock = get_node(mouselock_path)
@onready var deletesave = get_node(deletesave_path)
@onready var scroll = get_node(scroll_path)

func _ready():
	if FileAccess.file_exists(settings_path):
		load_settings()
	else: 
		save_defaults()
	
	scroll.get_v_scroll_bar().connect("item_rect_changed", Callable(self, "on_scrollbar_changed"))
	after_ready = true

### SIGNALS

func on_displaymode_changed(index: int):
	var win = get_window()
	match index:
		0: #windowed
			win.mode = Window.MODE_WINDOWED
			win.move_to_center()
			win.borderless = false
		1: #borderless
			win.mode = Window.MODE_FULLSCREEN #TODO: is this true borderless? check
			win.borderless = true
		2: #fullscreen
			win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			win.borderless = false
		3: #maximized
			win.mode = Window.MODE_MAXIMIZED #TODO: if win is unmaximized, this setting doesnt change
			win.borderless = false
	print("display settings changed")
	save_setting("DisplayMode", index)

#func on_resolutionscale_changed(index: int): #not fully implemented
	#w.viewport_size_ignore = true
	#match index:
		#0:
			#w.viewport_size_ignore = false
			##world._on_viewport_size_changed()
			#get_window().set_size(get_window().get_size()) #set window size so we can trigger _on_viewport_size_changed everywhere
		#1: w.resolution_scale = 1.0
		#2: w.resolution_scale = 2.0
		#3: w.resolution_scale = 3.0
		#4: w.resolution_scale = 4.0
		#5: w.resolution_scale = 5.0
		#6: w.resolution_scale = 6.0
		#7: w.resolution_scale = 7.0
		#8: w.resolution_scale = 8.0
	
	#if w.has_node("TitleCam"):
		#w.get_node("TitleCam").zoom = Vector2(1 / w.resolution_scale, 1 / w.resolution_scale)
	##world.get_node("UILayer").scale = Vector2(world.resolution_scale, world.resolution_scale)
	##TODO: make sure this carrys over for playercamera
	#if get_tree().get_nodes_in_group("CameraLimiters").size() != 0:
		#for c in get_tree().get_nodes_in_group("CameraLimiters"):
			#c._on_viewport_size_changed()
	#
	#save_setting("ResolutionScale", index)


func on_mastervolume_changed(value):
	var db = get_percent_as_db(value)
	#print(db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),db)
	if not w.get_node("MenuLayer/Options").hidden and after_ready:
		am.play("sound_test", null, "master") #play on master
	mastervolume.get_node("Label").text = "Master Volume: Muted" if value == 0 else "Master Volume: " + str(value) + "0 %"
	save_setting("MasterVolume", value)

func on_musicvolume_changed(value):
	var db = get_percent_as_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),db)
	if not w.get_node("MenuLayer/Options").hidden and after_ready:
		am.play_sfx("sound_test")
	musicvolume.get_node("Label").text = "Music Volume: Muted" if value == 0 else "Music Volume: " + str(value) + "0 %"
	save_setting("MusicVolume", value)

func on_sfxvolume_changed(value):
	var db = get_percent_as_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),db)
	if not w.get_node("MenuLayer/Options").hidden and after_ready:
		am.play("sound_test")
	sfxvolume.get_node("Label").text = "SFX Volume: Muted" if value == 0 else "SFX Volume: " + str(value) + "0 %"
	save_setting("SFXVolume", value)


func on_return():
	if w.has_node("MenuLayer/PauseMenu"):
		w.get_node("MenuLayer/PauseMenu").visible = true
		w.get_node("MenuLayer/PauseMenu").do_focus()
	if w.has_node("MenuLayer/TitleScreen"):
		w.get_node("MenuLayer/TitleScreen").visible = true
		w.get_node("MenuLayer/TitleScreen").do_focus()
		
	if w.has_node("MenuLayer/Options"):
		w.get_node("MenuLayer/Options").queue_free()
	else:
		get_parent().queue_free()




func on_reset():
	save_defaults()
	load_settings()

func on_mouselock(value):
	if value: Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	save_setting("MouseLock", value)

func on_deletesave():
	var files = []
	var dir = DirAccess.open("user://")
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
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
	
	on_reset()
	deletesave.text = "Done"

func on_scrollbar_changed():
	scroll.get_v_scroll_bar().size.y = scroll.size.y - 48


### SAVE/LOAD

func save_defaults():
	write_data(default)

func save_setting(setting, setting_value):
	var data = read_data()
	data[setting] = setting_value
	write_data(data)

func load_settings():
	var data = read_data()
	
	mastervolume.get_node("Slider").value = data["MasterVolume"]
	on_mastervolume_changed(data["MasterVolume"])
	musicvolume.get_node("Slider").value = data["MusicVolume"]
	on_musicvolume_changed(data["MusicVolume"])
	sfxvolume.get_node("Slider").value = data["SFXVolume"]
	on_sfxvolume_changed(data["SFXVolume"])
	
	displaymode.selected = data["DisplayMode"]
	on_displaymode_changed(data["DisplayMode"])
	#resolutionscale.selected = data["ResolutionScale"]
	#on_resolutionscale_changed(data["ResolutionScale"])
	
	mouselock.button_pressed = data["MouseLock"]
	on_mouselock(data["MouseLock"])


func write_data(data):
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(var_to_str(data))
		file.close()
		print("settings data saved")
	else:
		printerr("ERROR: settings data could not be saved!")

func read_data() -> Dictionary:
	var data
	if FileAccess.file_exists(settings_path):
		var file = FileAccess.open(settings_path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var test_json_conv = JSON.new()
			test_json_conv.parse(text)
			data = test_json_conv.get_data()
			file.close()
	else: 
		printerr("ERROR: could not load settings data")
	return data


### HELPER GETTERS

func get_percent_as_db(value) -> float:
	value = int(value)
	var db: float
	match value:
		0: db = -80
		1: db = -20
		2: db = -13.9794
		3: db = -10.4576
		4: db = -7.9588
		5: db = -6.0206
		6: db = -4.4370 
		7: db = -3.0980
		8: db = -1.9382 
		9: db = -0.9151
		10: db = 0
		11: db = 0.8279 
		12: db = 1.5836 
		13: db = 2.2789
		14: db = 2.9226
		15: db = 3.5218
		16: db = 4.0824
		17: db = 4.6090
		18: db = 5.1055
		19: db = 5.5751 
		20: db = 6.0206
		_: db = 0
		
	return db


### MISC

func do_focus():
	mastervolume.get_node("Slider").grab_focus()
