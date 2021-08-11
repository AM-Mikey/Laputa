extends Control

const CONTROLLERCONFIG = preload("res://src/UI/Options/ControllerConfig.tscn")

var input_map_path = "user://inputmap.json"

var can_change_key = false
var action_string
var actions = []
var debug_actions = []


var path_string = "MarginContainer/VBoxContainer/ScrollContainers/Normal/VBoxContainer"
var debug_path_string = "MarginContainer/VBoxContainer/ScrollContainers/Debug/VBoxContainer"

onready var world = get_tree().get_root().get_node("World")

func _ready():
	#add_child(CONTROLLERCONFIG.instance())
#	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
#	_on_viewport_size_changed()



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
		b.connect("pressed", self, "mark_button_normal", [b.get_parent().name])
		actions.append(b.get_parent().name)
		#print(b.get_parent().name)
	
	for b in buttons_debug:
		b.connect("pressed", self, "mark_button_debug", [b.get_parent().name])
		debug_actions.append(b.get_parent().name)
		#print(b.get_parent().name)
	
	_set_keys()  
  
func get_first_valid_input(j):
			var index = 0
			var good_input = InputMap.get_action_list(j)[index]
			while not good_input is InputEventKey and not good_input is InputEventMouseButton and index < InputMap.get_action_list(j).size() - 1:
				index +=1
				good_input = InputMap.get_action_list(j)[index]
			
			if not good_input is InputEventKey and not good_input is InputEventMouseButton:
				return null
			else:
				return good_input

func _set_keys():
	for j in actions:
		get_node(path_string + "/" + str(j) + "/Button").set_pressed(false)
		if !InputMap.get_action_list(j).empty():
			var input = get_first_valid_input(j)
			if input != null:
				if input is InputEventKey:
					get_node(path_string + "/" + str(j) + "/Button").set_text(input.as_text())
				elif input is InputEventMouseButton:
					var mouse_index
					match input.button_index:
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
			var input = get_first_valid_input(j)
			if input != null:
				if input is InputEventKey:
					get_node(debug_path_string + "/" + str(j) + "/Button").set_text(input.as_text())
				elif input is InputEventMouseButton:
					var mouse_index
					match input.button_index:
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


func mark_button_normal(string):
	can_change_key = true
	action_string = string
	
	for j in actions:
		if j != string:
			get_node(path_string + "/" + str(j) + "/Button").set_pressed(false)

func mark_button_debug(string):
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
		var input = get_first_valid_input(action_string)
		if input != null:
			InputMap.action_erase_event(action_string, input)
	
	#Check if new key was assigned somewhere
	var all_actions = actions + debug_actions
	for i in all_actions:
		if InputMap.action_has_event(i, new_key):
			InputMap.action_erase_event(i, new_key)
			
			
	#Add new Key
	InputMap.action_add_event(action_string, new_key)
	
	save_input_map()
	_set_keys()



func save_input_map():
	var data = {}
	var input_actions = InputMap.get_actions()
	for a in input_actions:
		var inputs = []
		for i in InputMap.get_action_list(a):
				if i is InputEventMouseButton:
					inputs.append(["mouse", i.button_index])
				if i is InputEventKey:
					inputs.append(["key", i.scancode])
				if i is InputEventJoypadButton:
					inputs.append(["joy", i.button_index])
		data[a] = inputs
	
	
	var file = File.new()
	var file_written = file.open(input_map_path, File.WRITE)
	if file_written == OK:
		#file.store_var(data)
		file.store_string(var2str(data))
		file.close()
		print("input map data saved")
	else:
		printerr("ERROR: input map data could not be saved!")


func load_input_map():
	var data
	
	var file = File.new()
	if file.file_exists(input_map_path):
		var file_read = file.open(input_map_path, File.READ)
		if file_read == OK:
			var text = file.get_as_text()
			data = JSON.parse(text).result
			#data = file.get_var()
			file.close()
			
			for a in data.keys():
				InputMap.action_erase_events(a)
				for i in data[a]:
					var new_input
					match i.front():
						"mouse":
							new_input = InputEventMouseButton.new()
							new_input.set_button_index(i.back())
						"key":
							new_input = InputEventKey.new()
							new_input.set_scancode(i.back())
						"joy":
							new_input = InputEventJoypadButton.new()
							new_input.set_button_index(i.back())

					InputMap.action_add_event(a, new_input)

	else: 
		printerr("ERROR: could not load input map data")
	
	
func _on_Return_pressed():
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").focus()
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").focus()
	
	if world.has_node("UILayer/Options"):
		world.get_node("UILayer/Options").queue_free()
	else:
		get_parent().queue_free()



func _on_Mikey_pressed():
	var dict = {
		"ui_left": KEY_A,
		"ui_right": KEY_D,
		"ui_up": KEY_W,
		"ui_down": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"look_up": KEY_W,
		"look_down": KEY_S,
		"jump": KEY_SPACE,
		"inspect": KEY_E,
		"inventory": KEY_I
		}
	for k in dict.keys():
		InputMap.action_erase_events(k) #delete all other binds
		var new_input = InputEventKey.new()
		new_input.set_scancode((dict[k]))
		InputMap.action_add_event(k, new_input)

	var dict2 = {
		"fire_manual": BUTTON_LEFT,
		"fire_automatic": BUTTON_RIGHT,
		"weapon_right": BUTTON_WHEEL_DOWN,
		"weapon_left": BUTTON_WHEEL_UP
		}
	for k in dict2.keys():
		InputMap.action_erase_events(k) #delete all other binds
		var new_input = InputEventMouseButton.new()
		new_input.button_index = dict2[k]
		InputMap.action_add_event(k, new_input)

func _on_CS_pressed():
	var dict = {
		"ui_left": KEY_LEFT,
		"ui_right": KEY_RIGHT,
		"ui_up": KEY_UP,
		"ui_down": KEY_DOWN,
		"move_left": KEY_LEFT,
		"move_right": KEY_RIGHT,
		"look_up": KEY_UP,
		"look_down": KEY_DOWN,
		"jump": KEY_Z,
		"fire_manual": KEY_X,
		"fire_automatic": KEY_SHIFT,
		"inspect": KEY_C,
		"weapon_right": KEY_A,
		"weapon_left": KEY_S,
		"inventory": KEY_Q
		}
	for k in dict.keys():
		InputMap.action_erase_events(k) #delete all other binds
		var new_input = InputEventKey.new()
		new_input.set_scancode((dict[k]))
		InputMap.action_add_event(k, new_input)
		

#func _on_viewport_size_changed():
#	rect_size = get_tree().get_root().size / world.resolution_scale

func focus():
	$MarginContainer/VBoxContainer/ScrollContainers/Normal/VBoxContainer/jump/Button.grab_focus()
