extends Control

const CONTROLLERCONFIG = preload("res://src/UI/Options/ControllerConfig.tscn")

var input_map_path = "user://inputmap.json"

var assignment_mode = false
var button_ignore = false
var action_string
var actions = []
var debug_actions = []

var active_preset = 0

export(NodePath) var buttons
onready var p_button = get_node(buttons)
export(NodePath) var focus
export(NodePath) var preset_path
onready var preset = get_node(preset_path)

onready var world = get_tree().get_root().get_node("World")



func _ready():
	preset.select(0)
	var buttons_normal = []
	
	for c in p_button.get_children():
		var subchildren = c.get_children()
		for s in subchildren:
			if s is Button:
				buttons_normal.append(s)

	for b in buttons_normal:
		b.connect("pressed", self, "_mark_button_normal", [b.get_parent().name])
		actions.append(b.get_parent().name)

	_set_keys()



func _set_keys():
	for j in actions:
		var button = p_button.get_node(str(j) + "/Button")
		button.set_pressed(false)
		
		if InputMap.get_action_list(j).empty():
			button.set_text("No Button!")
			#button.set_pressed(false)
			return
		
		var input = _get_first_valid_input(j)
		if input != null:
			if input is InputEventKey:
				button.set_text(input.as_text())
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
				button.set_text(mouse_index)
			
#			print("/////////////")
#			print ("input" + str(input))
#			print(_get_first_valid_input("ui_accept"))
#			if input == _get_first_valid_input("ui_accept"): #toggle off the button if we're not pressing our ui_accept
#				print("bingo")
##			else:
#			button.set_pressed(false)


  
func _get_first_valid_input(j):
			var index = 0
			var good_input = InputMap.get_action_list(j)[index]
			while not good_input is InputEventKey and not good_input is InputEventMouseButton and index < InputMap.get_action_list(j).size() - 1:
				index +=1
				good_input = InputMap.get_action_list(j)[index]
			
			if not good_input is InputEventKey and not good_input is InputEventMouseButton:
				return null
			else:
				return good_input



func _mark_button_normal(string):
	if button_ignore:
		button_ignore = false
		
		for j in actions:
			if j == string:
				p_button.get_node(str(j) + "/Button").set_pressed(false)
		
	else:
		assignment_mode = true
		action_string = string
		
		for j in actions:
			if j != string:
				p_button.get_node(str(j) + "/Button").set_pressed(false)



func _input(event):
	if (event is InputEventKey or event is InputEventMouseButton) and assignment_mode:
		print("second_input")
		_change_key(event)
		assignment_mode = false
		
		var accept_event = _get_first_valid_input("ui_accept") #prevent us from entering another assignment mode when event is accept_event
		if event is InputEventKey and accept_event is InputEventKey:
			if event.scancode == accept_event.scancode:
				button_ignore = true
		if event is InputEventMouseButton and accept_event is InputEventMouseButton:
			if event.button_index == accept_event.button_index:
				button_ignore = true



func _change_key(new_key):
	#Delete key of pressed button
	if !InputMap.get_action_list(action_string).empty():
		var input = _get_first_valid_input(action_string)
		if input != null:
			InputMap.action_erase_event(action_string, input)
	
	#Check if new key was assigned somewhere 		#pass for now
#	var all_actions = actions + debug_actions
#	for i in all_actions:
#		if InputMap.action_has_event(i, new_key):
#			InputMap.action_erase_event(i, new_key)
			
			
	#Add new Key
	InputMap.action_add_event(action_string, new_key)
	
	
	#alias action
	var alias_action_string
	match action_string:
		"move_left": alias_action_string = "ui_left"
		"move_right": alias_action_string = "ui_right"
		"look_up": alias_action_string = "ui_up"
		"look_down": alias_action_string = "ui_down"

	if alias_action_string != null:
		if !InputMap.get_action_list(alias_action_string).empty():
			var input = _get_first_valid_input(alias_action_string)
			if input != null:
				InputMap.action_erase_event(alias_action_string, input)
		InputMap.action_add_event(alias_action_string, new_key)
	
	###
	
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


func _on_ItemList_item_selected(index):
	preset.select(active_preset)
	if index != 0:
		active_preset = index
		$ConfirmationDialog.popup()

func _on_ConfirmationDialog_confirmed():
	preset.select(active_preset)

func focus():
	get_node(focus).grab_focus()







