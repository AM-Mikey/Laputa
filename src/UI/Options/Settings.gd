extends Control

var settings_path = "user://settings.json"

export(NodePath) var mastervolume_path
export(NodePath) var sfxvolume_path
export(NodePath) var musicvolume_path
export(NodePath) var displaymode_path
export(NodePath) var resolutionscale_path
export(NodePath) var mouselock_path
export(NodePath) var deletesave_path
export(NodePath) var scroll_path

var default = {
	"MasterVolume": 10.0,
	"MusicVolume": 0.0,
	"SFXVolume" : 10.0,
	"DisplayMode": 3,
	"ResolutionScale": 0,
	"MouseLock": false,
	}
var after_ready = false

onready var w = get_tree().get_root().get_node("World")

onready var mastervolume = get_node(mastervolume_path)
onready var sfxvolume = get_node(sfxvolume_path)
onready var musicvolume = get_node(musicvolume_path)
onready var displaymode = get_node(displaymode_path)
onready var resolutionscale = get_node(resolutionscale_path)
onready var mouselock = get_node(mouselock_path)
onready var deletesave = get_node(deletesave_path)
onready var scroll = get_node(scroll_path)

func _ready():
	var file = File.new()
	if file.file_exists(settings_path):
		load_settings()
	else: 
		save_defaults()
	
	scroll.get_v_scrollbar().connect("item_rect_changed", self, "on_scrollbar_changed")
	after_ready = true

### SIGNALS

func on_displaymode_changed(index: int):
	OS.set_window_maximized(false)
	match index:
		0: #windowed
			OS.set_window_fullscreen(false)
			OS.set_borderless_window(false)
#			OS.set_window_size(OS.get_window_size()) #set window size so we can trigger _on_viewport_size_changed everywhere
		1: #borderless
			OS.set_window_fullscreen(false)
			OS.set_borderless_window(true)
			OS.set_window_size(OS.get_screen_size())
			OS.set_window_position(Vector2.ZERO)
		2: #fullscreen
			OS.set_window_fullscreen(true)
		3: #maximized
			OS.set_window_fullscreen(false)
			OS.set_borderless_window(false)
			OS.set_window_maximized(true)
	print("display settings changed")
	save_setting("DisplayMode", index)

func on_resolutionscale_changed(index: int):
	match index:
		0:
			w.viewport_size_ignore = false
			#world._on_viewport_size_changed()
			OS.set_window_size(OS.get_window_size()) #set window size so we can trigger _on_viewport_size_changed everywhere
		1:
			w.resolution_scale = 1.0
			w.viewport_size_ignore = true
		2:
			w.resolution_scale = 2.0
			w.viewport_size_ignore = true
		3:
			w.resolution_scale = 3.0
			w.viewport_size_ignore = true
		4:
			w.resolution_scale = 4.0
			w.viewport_size_ignore = true
	
	if w.has_node("TitleCam"):
		w.get_node("TitleCam").zoom = Vector2(1 / w.resolution_scale, 1 / w.resolution_scale)
	#world.get_node("UILayer").scale = Vector2(world.resolution_scale, world.resolution_scale)
	#TODO: make sure this carrys over for playercamera
	if get_tree().get_nodes_in_group("CameraLimiters").size() != 0:
		for c in get_tree().get_nodes_in_group("CameraLimiters"):
			c._on_viewport_size_changed()
	
	save_setting("ResolutionScale", index)


func on_mastervolume_changed(value):
	var db = get_percent_as_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),db)
	if not w.get_node("UILayer/Options").hidden and after_ready:
		am.play_master("sound_test")
	mastervolume.get_node("Label").text = "Master Volume: Muted" if value == 0 else "Master Volume: " + str(value) + "0 %"
	save_setting("MasterVolume", value)

func on_musicvolume_changed(value):
	var db = get_percent_as_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),db)
	if not w.get_node("UILayer/Options").hidden and after_ready:
		am.play_music("sound_test")
	musicvolume.get_node("Label").text = "Music Volume: Muted" if value == 0 else "Music Volume: " + str(value) + "0 %"
	save_setting("MusicVolume", value)

func on_sfxvolume_changed(value):
	var db = get_percent_as_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"),db)
	if not w.get_node("UILayer/Options").hidden and after_ready:
		am.play("sound_test")
	sfxvolume.get_node("Label").text = "SFX Volume: Muted" if value == 0 else "SFX Volume: " + str(value) + "0 %"
	save_setting("SFXVolume", value)


func on_return():
	if w.has_node("UILayer/PauseMenu"):
		w.get_node("UILayer/PauseMenu").visible = true
		w.get_node("UILayer/PauseMenu").focus()
	if w.has_node("UILayer/TitleScreen"):
		w.get_node("UILayer/TitleScreen").visible = true
		w.get_node("UILayer/TitleScreen").focus()
		
	if w.has_node("UILayer/Options"):
		w.get_node("UILayer/Options").queue_free()
	else:
		get_parent().queue_free()




func on_reset():
	save_defaults()
	#yield(get_tree(), "idle_frame")
	load_settings()

func on_mouselock(value):
	if value: Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	save_setting("MouseLock", value)

func on_deletesave():
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
	
	on_reset()
	deletesave.text = "Done"

func on_scrollbar_changed():
	scroll.get_v_scrollbar().rect_size.y = scroll.rect_size.y - 48


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
	resolutionscale.selected = data["ResolutionScale"]
	on_resolutionscale_changed(data["ResolutionScale"])
	
	mouselock.pressed = data["MouseLock"]
	on_mouselock(data["MouseLock"])


func write_data(data):
	var file = File.new()
	var file_written = file.open(settings_path, File.WRITE)
	if file_written == OK:
		file.store_string(var2str(data))
		file.close()
		print("settings data saved")
	else:
		printerr("ERROR: settings data could not be saved!")

func read_data() -> Dictionary:
	var data
	var file = File.new()
	if file.file_exists(settings_path):
		var file_read = file.open(settings_path, File.READ)
		if file_read == OK:
			var text = file.get_as_text()
			data = JSON.parse(text).result
			file.close()
	else: 
		printerr("ERROR: could not load settings data")
	return data


### HELPER GETTERS

func get_percent_as_db(value) -> float:
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

func focus():
	mastervolume.get_node("Slider").grab_focus()
