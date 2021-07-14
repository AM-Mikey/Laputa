extends Control

const CONTROLLERCONFIG = preload("res://src/UI/ControllerConfig.tscn")

var config_path = "user://config.json"

var can_change_key = false
var action_string
var actions = []
var debug_actions = []


var path_string = "MarginContainer/MarginContainer/VBoxContainer/ScrollContainers/Normal/VBoxContainer"
var debug_path_string = "MarginContainer/MarginContainer/VBoxContainer/ScrollContainers/Debug/VBoxContainer"

onready var world = get_tree().get_root().get_node("World")

func _ready():
	add_child(CONTROLLERCONFIG.instance())
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	
	var buttons_normal = []
	var buttons_debug = []
	for c in get_node(path_string).get_children():
		var subchildren = c.get_children()
		for s in subchildren:
			if s is Button:
				buttons_normal.append(s)
	for c in get_node(debug_path_string).get_children():
		var subchildren = c.get_children()
		for s in subchildren:
			if s is Button:
				buttons_debug.append(s)
			
	for b in buttons_normal:
		b.connect("pressed", self, "on_button_normal_pressed", [b.get_parent().name])
		actions.append(b.get_parent().name)
		print(b.get_parent().name)
	
	for b in buttons_debug:
		b.connect("pressed", self, "on_button_debug_pressed", [b.get_parent().name])
		debug_actions.append(b.get_parent().name)
		print(b.get_parent().name)
	
	_set_keys()  
  

func _set_keys():
	for j in actions:
		get_node(path_string + "/" + str(j) + "/Button").set_pressed(false)
		if !InputMap.get_action_list(j).empty():
			if InputMap.get_action_list(j)[0] is InputEventKey:
				get_node(path_string + "/" + str(j) + "/Button").set_text(InputMap.get_action_list(j)[0].as_text())
			if InputMap.get_action_list(j)[0] is InputEventMouseButton:
				var mouse_index
				#get_node(debug_path_string + str(j) + "/Button").set_text()
				match InputMap.get_action_list(j)[0].button_index:
					1: mouse_index = "LMB"
					2: mouse_index = "RMB"
					3: mouse_index = "MMB"
					4: mouse_index = "MWHEELUP"
					5: mouse_index = "MWHEELDOWN"
					6: mouse_index = "MWHEELLEFT"
					7: mouse_index = "MWHEELRIGHT"
					8: mouse_index = "M4"
					9: mouse_index = "M5"
				get_node(path_string + "/" + str(j) + "/Button").set_text(mouse_index)
		else:
			get_node(path_string + "/" + str(j) + "/Button").set_text("No Button!")

	for j in debug_actions:
		get_node(debug_path_string + "/" + str(j) + "/Button").set_pressed(false)
		if !InputMap.get_action_list(j).empty():
			if InputMap.get_action_list(j)[0] is InputEventKey:
				get_node(debug_path_string + "/" + str(j) + "/Button").set_text(InputMap.get_action_list(j)[0].as_text())
			if InputMap.get_action_list(j)[0] is InputEventMouseButton:
				var mouse_index
				#get_node(debug_path_string + str(j) + "/Button").set_text()
				match InputMap.get_action_list(j)[0].button_index:
					1: mouse_index = "LMB"
					2: mouse_index = "RMB"
					3: mouse_index = "MMB"
					4: mouse_index = "MWHEELUP"
					5: mouse_index = "MWHEELDOWN"
					6: mouse_index = "MWHEELLEFT"
					7: mouse_index = "MWHEELRIGHT"
					8: mouse_index = "M4"
					9: mouse_index = "M5"
				get_node(debug_path_string + "/" + str(j) + "/Button").set_text(mouse_index)
		else:
			get_node(debug_path_string + "/" + str(j) + "/Button").set_text("No Button!")


func on_button_normal_pressed(string):
	_mark_button_normal(string)
	print("pressed button: " + string)

func on_button_debug_pressed(string):
	_mark_button_debug(string)
	print("pressed button: " + string)
	
func _mark_button_normal(string):
	can_change_key = true
	action_string = string
	
	for j in actions:
		if j != string:
			get_node(path_string + "/" + str(j) + "/Button").set_pressed(false)

func _mark_button_debug(string):
	can_change_key = true
	action_string = string
	
	for j in debug_actions:
		if j != string:
			get_node(debug_path_string + "/" + str(j) + "/Button").set_pressed(false)

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton: 
		if can_change_key:
			_change_key(event)
			can_change_key = false


func _change_key(new_key):
	#Delete key of pressed button
	if !InputMap.get_action_list(action_string).empty():
		InputMap.action_erase_event(action_string, InputMap.get_action_list(action_string)[0])
	
	#Check if new key was assigned somewhere
	var all_actions = actions + debug_actions
	for i in all_actions:
		if InputMap.action_has_event(i, new_key):
			InputMap.action_erase_event(i, new_key)
			
			
	#Add new Key
	InputMap.action_add_event(action_string, new_key)
	
	_set_keys()




func save_to_file():
	var keyboard_input_map = {}
	var input_actions = InputMap.get_actions()
	for i in input_actions:
		keyboard_input_map[i] = InputMap.get_action_list(i)[0]

	print(keyboard_input_map)
	
	var data = {}
	data[keyboard_input_map] = keyboard_input_map
	
	var file = File.new()
	var file_written = file.open(config_path, File.WRITE)
	if file_written == OK:
		file.store_string(var2str(data))
		file.close()
		print("config data saved")
	else:
		printerr("ERROR: config data could not be saved!")


func _on_Return_pressed():
	save_to_file()
	queue_free()

func _on_viewport_size_changed():
	$MarginContainer.rect_size = get_tree().get_root().size / world.resolution_scale
