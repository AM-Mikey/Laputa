extends Node


const SETTINGS_FILE = "user://editor.json"

var editor_window = [0, 25, 250, 450]
var inspector_window = [750, 25, 200, 450]
var default = {
	"EditorWindow": editor_window,
	"InspectorWindow": inspector_window,
	}

onready var editor = get_parent()

func _ready():
	var file = File.new()
	if file.file_exists(SETTINGS_FILE):
		load_settings()
	else: 
		save_defaults()
		load_settings()


func save_editor_windows():
	pass
	

func load_settings():
	var data = read_data()
	
	
	var data1 = data["EditorWindow"]
	editor.get_node("Main").rect_position = Vector2(data1[0], data1[1])
	editor.get_node("Main").rect_size = Vector2(data1[2], data1[3])
	
	var data2 = data["InspectorWindow"]
	editor.get_node("Secondary").rect_position = Vector2(data2[0], data2[1])
	editor.get_node("Secondary").rect_size = Vector2(data2[2], data2[3])
	

#HELPERS

func save_defaults():
	write_data(default)


func write_data(data):
	var file = File.new()
	var file_written = file.open(SETTINGS_FILE, File.WRITE)
	if file_written == OK:
		file.store_string(var2str(data))
		file.close()
		print("settings data saved")
	else:
		printerr("ERROR: settings data could not be saved!")


func read_data() -> Dictionary:
	var data
	var file = File.new()
	if file.file_exists(SETTINGS_FILE):
		var file_read = file.open(SETTINGS_FILE, File.READ)
		if file_read == OK:
			var text = file.get_as_text()
			data = JSON.parse(text).result
			file.close()
	else: 
		printerr("ERROR: could not load settings data")
	return data
