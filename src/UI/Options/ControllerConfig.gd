extends Control

var input_map_path = "user://inputmap.json"
onready var world = get_tree().get_root().get_node("World")

var compass_distance = 8

onready var action_options = get_tree().get_nodes_in_group("ActionOptions")

var action_dict = {
	"": "None",
	"jump": "Jump",
	"fire_manual": "Fire",
	"fire_automatic": "Autofire",
	"inspect": "Inspect",
	"inventory": "Inventory",
	"gun_left": "Next Gun",
	"gun_right": "Last Gun",
	"pause": "Pause",
}

var button_dict = {
	"DpadUp": JOY_DPAD_UP,
	"DpadLeft": JOY_DPAD_LEFT,
	"DpadRight": JOY_DPAD_RIGHT,
	"DpadDown": JOY_DPAD_DOWN,
	"Select": JOY_SELECT,
	"Start": JOY_START,
	"FaceUp": JOY_DS_X,
	"FaceLeft": JOY_DS_Y,
	"FaceRight": JOY_DS_A,
	"FaceDown": JOY_DS_B,
	"L1": JOY_L,
	"L2": JOY_L2,
	"L3": JOY_L3,
	"R1": JOY_R,
	"R2": JOY_R2,
	"R3": JOY_R3,
	}

func _ready():
	for o in action_options:
		for a in action_dict:
			o.add_item(action_dict[a])
#			if o.get_signal_list().size() == 0:
			#o.connect("item_selected", self, "_set_button_action", [o.name])
	#yield(get_tree(), "idle_frame")
	_setup_action_options()


func _setup_action_options():
	for o in action_options:
		#print(o.name)
		
#		var found_action
		
		for a in InputMap.get_actions():
			if a in action_dict.keys():
				for e in InputMap.get_action_list(a):
					if e is InputEventJoypadButton:
#						print("e.button_index : " + str(e.button_index))
#						print("button_dict[o.name] : " + str(button_dict[o.name]))
						if e.button_index == button_dict[o.name]:
							#print("YAHOO: " + o.name)
							o.modulate = Color.aqua
							o.select(action_dict.keys().find(a))
#							o.selected = action_dict.keys().find(a)

#		if found_action != null:
#			o.select(action_dict.keys().find(found_action))
#		else:
#			o.select(0) #"None"

#func _set_button_action (action_index, button_name):
#	var action = action_dict[action_dict.keys()[action_index]]
#	var event = InputEventJoypadButton.new()
#	event.set_button_index(button_dict[button_name])
#
#	#erase all other events that are the same button
#	for a in InputMap.get_actions():
#		if InputMap.action_has_event(a, event):
#			InputMap.action_erase_event(a,event)
#
#	#add the new event
#	if action != null:
#		InputMap.action_add_event(action, event)
#	save_input_map()

#func save_input_map():
#	var data = {}
#	var input_actions = InputMap.get_actions()
#	for a in input_actions:
#		var inputs = []
#		for i in InputMap.get_action_list(a):
#				if i is InputEventMouseButton:
#					inputs.append(["mouse", i.button_index])
#				if i is InputEventKey:
#					inputs.append(["key", i.scancode])
#				if i is InputEventJoypadButton:
#					inputs.append(["joy", i.button_index])
#		data[a] = inputs
#
#
#	var file = File.new()
#	var file_written = file.open(input_map_path, File.WRITE)
#	if file_written == OK:
#		#file.store_var(data)
#		file.store_string(var2str(data))
#		file.close()
#		print("input map data saved")
#	else:
#		printerr("ERROR: input map data could not be saved!")


#func load_input_map():
#	var data
#
#	var file = File.new()
#	if file.file_exists(input_map_path):
#		var file_read = file.open(input_map_path, File.READ)
#		if file_read == OK:
#			var text = file.get_as_text()
#			data = JSON.parse(text).result
#			file.close()
#
#			for a in data.keys():
#				InputMap.action_erase_events(a)
#				for i in data[a]:
#					var new_input
#					match i.front():
#						"mouse":
#							new_input = InputEventMouseButton.new()
#							new_input.set_button_index(i.back())
#						"key":
#							new_input = InputEventKey.new()
#							new_input.set_scancode(i.back())
#						"joy":
#							new_input = InputEventJoypadButton.new()
#							new_input.set_button_index(i.back())
#
#					InputMap.action_add_event(a, new_input)
#
#	else: 
#		printerr("ERROR: could not load input map data")







func _on_Default_pressed():
	pass # Replace with function body.






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



func focus():
	pass
	#op_l2.grab_focus()
