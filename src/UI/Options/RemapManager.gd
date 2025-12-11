extends Node

var input_map_path = "user://inputmap.json"

var action_buttons = {}
var action_button_is_red = []
var ignore_button_press = false
var current_listening_action = null
var action_button_panel_default_widths = {}
var action_button_panel_tween_time = 0.1
var button_text_color_temp = Color(0.988, 0.22, 0.22)

#note, combination inputs are not remapped using this system, such as ui_text_caret_word_left
#note2, some of these actions may need a default input along with the remapped one (ui_acept on enter for example) right now we don't do this.
#structure: "main_action": ["grouped_action_one"]
var action_groups = {
	"move_left": ["ui_left", "ui_text_caret_left"],
	"move_right": ["ui_right", "ui_text_caret_right"],
	"look_up": ["ui_up", "ui_text_caret_up"],
	"look_down": ["inspect", "ui_down", "ui_text_caret_down"],
	"jump": ["ui_accept"],
	"fire_manual": ["ui_cancel"],
	"fire_automatic": [],
	"inventory": [],
	"gun_right": [],
	"gun_left": [],
	"pause": []
	}

@onready var p = get_parent()
@onready var temp_action_keyboard_input = {
	"move_left": convert_input_event_to_array(get_action_input_event("move_left", "keyboard")),
	"move_right": convert_input_event_to_array(get_action_input_event("move_right", "keyboard")),
	"look_up": convert_input_event_to_array(get_action_input_event("look_up", "keyboard")),
	"look_down": convert_input_event_to_array(get_action_input_event("look_down", "keyboard")),
	"jump": convert_input_event_to_array(get_action_input_event("jump", "keyboard")),
	"fire_manual": convert_input_event_to_array(get_action_input_event("fire_manual", "keyboard")),
	"fire_automatic": convert_input_event_to_array(get_action_input_event("fire_automatic", "keyboard")),
	"gun_right": convert_input_event_to_array(get_action_input_event("gun_right", "keyboard")),
	"gun_left": convert_input_event_to_array(get_action_input_event("gun_left", "keyboard")),
	"inventory": convert_input_event_to_array(get_action_input_event("inventory", "keyboard")),
	"pause": convert_input_event_to_array(get_action_input_event("pause", "keyboard")),
	}
@onready var temp_action_controller_input = {
	"move_left": convert_input_event_to_array(get_action_input_event("move_left", "controller")),
	"move_right": convert_input_event_to_array(get_action_input_event("move_right", "controller")),
	"look_up": convert_input_event_to_array(get_action_input_event("look_up", "controller")),
	"look_down": convert_input_event_to_array(get_action_input_event("look_down", "controller")),
	"jump": convert_input_event_to_array(get_action_input_event("jump", "controller")),
	"fire_manual": convert_input_event_to_array(get_action_input_event("fire_manual", "controller")),
	"fire_automatic": convert_input_event_to_array(get_action_input_event("fire_automatic", "controller")),
	"gun_right": convert_input_event_to_array(get_action_input_event("gun_right", "controller")),
	"gun_left": convert_input_event_to_array(get_action_input_event("gun_left", "controller")),
	"inventory": convert_input_event_to_array(get_action_input_event("inventory", "controller")),
	"pause": convert_input_event_to_array(get_action_input_event("pause", "controller")),
	}



func set_temp_action_input(event, device_type):
	var input_array = convert_input_event_to_array(event)
	var temp_action_input
	match device_type:
		"keyboard":
			temp_action_input = temp_action_keyboard_input
		"controller":
			temp_action_input = temp_action_controller_input

	#check duplicate in temp (no need to check InputMap, temp already copies this)
	if temp_action_input.values().has(input_array):
		am.play("ui_deny")
		action_buttons[current_listening_action].set_pressed(false)
		current_listening_action = null
		print("already using this input")
	else:
		temp_action_input[current_listening_action] = input_array
		match device_type:
			"keyboard":
				p.set_button_text(true)
			"controller":
				p.set_action_button_icons(true)



func confirm_action_input(device_type):
	action_button_is_red.clear()
	var temp_action_input
	match device_type:
		"keyboard":
			temp_action_input = temp_action_keyboard_input
		"controller":
			temp_action_input = temp_action_controller_input
	for main_action in action_groups.keys():
		if temp_action_input.has(main_action):
			if temp_action_input[main_action] != null:
				var new_input = convert_array_to_input_event(temp_action_input[main_action])
				if new_input != null:
					erase_old_input(main_action, device_type)
					InputMap.action_add_event(main_action, new_input)
					for secondary_action in action_groups[main_action]:
						erase_old_input(secondary_action, device_type)
						InputMap.action_add_event(secondary_action, new_input)
	save_input_map()
	match device_type:
		"keyboard":
			p.set_button_text(false)
		"controller":
			p.set_action_button_icons(false)



### ANIMATION ###

func setup_action_button_panels():
	for action_box in p.action_selections.get_children():
		var panel = action_box.get_child(0)
		action_button_panel_default_widths[action_box.name] = panel.size.x
		panel.size.x = 0

func tween_in_button_panel(panel):
	var tween = create_tween()
	tween.tween_property(panel, "size", Vector2(action_button_panel_default_widths[panel.get_parent().name], panel.size.y), action_button_panel_tween_time)
	tween.play()

func tween_out_button_panel(panel):
	var tween = create_tween()
	tween.tween_property(panel, "size", Vector2(0.0, panel.size.y), action_button_panel_tween_time)
	tween.play()



### SAVE/LOAD ###

func save_input_map():
	var data = {}
	var input_actions = InputMap.get_actions()
	for a in input_actions:
		var inputs = []
		for i in InputMap.action_get_events(a): #TODO: disallow controller inputs while in keyboard config #convert to use the converter
				if i is InputEventMouseButton:
					inputs.append(["mouse", i.button_index])
				if i is InputEventKey:
					inputs.append(["key", i.keycode])
				if i is InputEventJoypadButton:
					inputs.append(["joy", i.button_index])
				if i is InputEventJoypadMotion:
					inputs.append(["joy_analog", i.axis, sign(i.axis_value)])
		data[String(a)] = inputs


	var file = FileAccess.open(input_map_path, FileAccess.WRITE)
	if file:
		file.store_string(var_to_str(data))
		file.close()
		print("input map data saved")
	else:
		printerr("ERROR: input map data could not be saved!")


func load_input_map(): #called on savesystem load options #TODO: migrate to Inputconfig script
	var data
	if FileAccess.file_exists(input_map_path):
		var file = FileAccess.open(input_map_path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var test_json_conv = JSON.new()
			test_json_conv.parse(text)
			data = test_json_conv.get_data()
			file.close()

			for a in data.keys():
				InputMap.action_erase_events(a)
				for i in data[a]:
					var new_input
					match i[0]:
						"mouse":
							new_input = InputEventMouseButton.new()
							new_input.set_button_index(i[1])
						"key":
							new_input = InputEventKey.new()
							new_input.set_keycode(i[1])
						"joy":
							new_input = InputEventJoypadButton.new()
							new_input.set_button_index(i[1])
						"joy_analog":
							new_input = InputEventJoypadMotion.new()
							new_input.axis = i[1]
							new_input.axis_value = i[2]

					InputMap.action_add_event(a, new_input) #TODO: joy analog might need deadzone set to 0 here

	else:
		printerr("ERROR: could not load input map data")



### HELPERS ###

func convert_input_event_to_array(event) -> Array:
	var out = []
	if event is InputEventMouseButton:
		out = ["mouse", event.button_index]
	if event is InputEventKey:
		out = ["key", event.keycode]
	if event is InputEventJoypadButton:
		out = ["joy", event.button_index]
	if event is InputEventJoypadMotion:
		out = ["joy_analog", event.axis, sign(event.axis_value)]
	return out


func convert_array_to_input_event(array) -> InputEvent:
	var out
	match array[0]:
		"mouse":
			out = InputEventMouseButton.new()
			out.button_index = array[1]
		"key":
			out = InputEventKey.new()
			out.keycode = array[1]
		"joy":
			out = InputEventJoypadButton.new()
			out.button_index = array[1]
		"joy_analog":
			out = InputEventJoypadMotion.new()
			out.axis = array[1]
			out.axis_value = array[2]
	return out


func get_action_input_event(action, device_type, index = 0):
	var all_input_events := InputMap.action_get_events(action)
	var good_input_events := []

	for e in all_input_events:
		match device_type:
			"keyboard":
				if e is InputEventKey or e is InputEventMouseButton:
					good_input_events.append(e)
					if good_input_events.size() == index + 1:
						return good_input_events[index]
			"controller":
				if e is InputEventJoypadButton or e is InputEventJoypadMotion:
					good_input_events.append(e)
					if good_input_events.size() == index + 1:
						return good_input_events[index]
	return null


func erase_old_input(action, device_type):
	if !InputMap.action_get_events(action).is_empty():
		var old_input = get_action_input_event(action, device_type)
		if old_input != null:
			InputMap.action_erase_event(action, old_input) #this works if there is only one keyboard/mousebutton input per action, including ui actions (or controller button/motion)
