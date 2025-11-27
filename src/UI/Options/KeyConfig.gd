extends Control

const CONTROLLERCONFIG = preload("res://src/UI/Options/ControllerConfig.tscn")

var input_map_path = "user://inputmap.json"

var ignore_button_press = false
var current_listening_action = null
var action_buttons = {}
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



var active_preset = 0

#@export var buttons: NodePath
#@onready var p_button = get_node(buttons)
@export var ui_focus: NodePath
@export var preset_path: NodePath

@onready var w = get_tree().get_root().get_node("World")

@onready var temp_action_keyboard_input = {
	"move_left": convert_input_event_to_array(get_first_keyboard_input("move_left")),
	"move_right": convert_input_event_to_array(get_first_keyboard_input("move_right")),
	"look_up": convert_input_event_to_array(get_first_keyboard_input("look_up")),
	"look_down": convert_input_event_to_array(get_first_keyboard_input("look_down")),
	"jump": convert_input_event_to_array(get_first_keyboard_input("jump")),
	"fire_manual": convert_input_event_to_array(get_first_keyboard_input("fire_manual")),
	"fire_automatic": convert_input_event_to_array(get_first_keyboard_input("fire_automatic")),
	"inventory": convert_input_event_to_array(get_first_keyboard_input("inventory")),
	"gun_right": convert_input_event_to_array(get_first_keyboard_input("gun_right")),
	"gun_left": convert_input_event_to_array(get_first_keyboard_input("gun_left")),
	"pause": convert_input_event_to_array(get_first_keyboard_input("pause")),
	}

#var preset_classic = {
	#"jump": KEY_X,
	#"fire_manual": KEY_C,
	#"fire_automatic": KEY_Z,
	#"move_left": KEY_LEFT,
	#"move_right": KEY_RIGHT,
	#"look_up": KEY_UP,
	#"look_down": KEY_DOWN,
	#"ui_accept": KEY_X,
	#"ui_cancel": KEY_C,
	#"inspect": KEY_DOWN,
	#"inventory": KEY_Q,
	#"gun_left": KEY_A,
	#"gun_right": KEY_S,
	#"pause": KEY_ESCAPE,
#}
#
#var preset_mouse = {
	#"jump": KEY_SPACE,
	#"fire_manual": MOUSE_BUTTON_LEFT,
	#"fire_automatic": MOUSE_BUTTON_RIGHT,
	#"move_left": KEY_A,
	#"move_right": KEY_D,
	#"look_up": KEY_W,
	#"look_down": KEY_S,
	#"ui_accept": KEY_E,
	#"ui_cancel": KEY_Q,
	#"inspect": KEY_E,
	#"inventory": KEY_TAB,
	#"gun_left": MOUSE_BUTTON_WHEEL_DOWN,
	#"gun_right": MOUSE_BUTTON_WHEEL_UP,
	#"pause": KEY_ESCAPE,
#}
#
#var preset_onehand = {
	#"jump": KEY_SHIFT,
	#"fire_manual": KEY_SPACE,
	#"fire_automatic": KEY_ALT,
	#"move_left": KEY_A,
	#"move_right": KEY_D,
	#"look_up": KEY_W,
	#"look_down": KEY_S,
	#"ui_accept": KEY_SPACE,
	#"ui_cancel": KEY_ESCAPE,
	#"inspect": KEY_S,
	#"inventory": KEY_TAB,
	#"gun_left": KEY_Q,
	#"gun_right": KEY_E,
	#"pause": KEY_ESCAPE,
#}


func _ready():
	for action_box in %ActionSelections.get_children():
		action_buttons[action_box.name] = action_box.get_child(1)
	for b in action_buttons.values():
		b.connect("pressed", Callable(self, "input_button_pressed").bind(b))
		b.connect("focus_entered", Callable(self, "input_button_focus_entered").bind(b))
		b.connect("focus_exited", Callable(self, "input_button_focus_exited").bind(b))

	set_button_text()
	setup_action_button_panels()



### ANIMATION ###

func setup_action_button_panels():
	for action_box in %ActionSelections.get_children():
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



### CHANGING ACTION INPUT ###

func input_button_pressed(button): #test this ignore
	current_listening_action = action_buttons.find_key(button)
	#if ignore_button_press:
		#ignore_button_press = false
		#button.set_pressed(false)
	#else:
	for i in action_buttons.values(): #deselect all other buttons
		if i != button:
			i.set_pressed(false)


func _input(event):
	if (event is InputEventKey) and current_listening_action != null: #or event is InputEventMouseButton #TODO implement mouseaskey
		get_viewport().set_input_as_handled()
		set_temp_action_keyboard_input(event)
		current_listening_action = null

		#non issue, buttons only work on click right now
		#var accept_input_event = _get_first_valid_input("ui_accept") #prevent us from entering another assignment mode when event is accept_event
		#if event is InputEventKey and accept_input_event is InputEventKey:
			#if event.keycode == accept_input_event.keycode:
				#ignore_button_press = true
		#if event is InputEventMouseButton and accept_input_event is InputEventMouseButton:
			#if event.button_index == accept_input_event.button_index:
				#ignore_button_press = true



func set_temp_action_keyboard_input(event):
	var input_array = convert_input_event_to_array(event)

	#check duplicate in temp
	if temp_action_keyboard_input.values().has(input_array):
		am.play("ui_deny")
		action_buttons[current_listening_action].set_pressed(false)
		current_listening_action = null
		print("already using this input")
	##check duplicate in InputMap
	#elif InputMap.
	else:
		temp_action_keyboard_input[current_listening_action] = input_array
		set_button_text(true)



func confirm_action_keyboard_input():
	for main_action in action_groups.keys():
		if temp_action_keyboard_input[main_action] != null:
			var new_input = convert_array_to_input_event(temp_action_keyboard_input[main_action])
			if new_input != null:
				erase_old_keyboard_input(main_action)
				InputMap.action_add_event(main_action, new_input)
				for secondary_action in action_groups[main_action]:
					erase_old_keyboard_input(secondary_action)
					InputMap.action_add_event(secondary_action, new_input)
	save_input_map()
	set_button_text(false)




func set_button_text(temp = false):
	if temp:
		var active_button = action_buttons[current_listening_action]
		active_button.add_theme_color_override("font_color", button_text_color_temp)
		active_button.add_theme_color_override("font_focus_color", button_text_color_temp)
		active_button.add_theme_color_override("font_pressed_color", button_text_color_temp)
		active_button.add_theme_color_override("font_hover_color", button_text_color_temp)
		active_button.add_theme_color_override("font_hover_pressed_color", button_text_color_temp)

	for button in action_buttons.values():
		if !temp:
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_focus_color")
			button.remove_theme_color_override("font_pressed_color")
			button.remove_theme_color_override("font_hover_color")
			button.remove_theme_color_override("font_hover_pressed_color")

		var action = action_buttons.find_key(button)
		var input
		if temp:
			input = temp_action_keyboard_input[action]
		else:
			input = convert_input_event_to_array(get_first_keyboard_input(action))

		if InputMap.action_get_events(action).is_empty():
			button.set_text("No Button!")
		elif input != null:
			var new_text: String
			match input[0]:
				"key":
					new_text = OS.get_keycode_string(input[1])
				"mouse":
					var mouse_button_string
					match input[1]:
						1: mouse_button_string = "LMB"
						2: mouse_button_string = "RMB"
						3: mouse_button_string = "MMB"
						4: mouse_button_string = "MWHEELUP"
						5: mouse_button_string = "MWHEELDOWN"
						6: mouse_button_string = "MWHEELLEFT"
						7: mouse_button_string = "MWHEELRIGHT"
						8: mouse_button_string = "M4"
						9: mouse_button_string = "M5"
					new_text = mouse_button_string
			if new_text.length() > 6:
				new_text = new_text.left(4) + "..."
			button.text = new_text



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

func get_first_keyboard_input(action):
			var index = 0
			var good_input = InputMap.action_get_events(action)[index]
			while !good_input is InputEventKey and !good_input is InputEventMouseButton and index < InputMap.action_get_events(action).size() - 1:
				index +=1
				good_input = InputMap.action_get_events(action)[index]
			if !good_input is InputEventKey and !good_input is InputEventMouseButton:
				return null
			else:
				return good_input


func erase_old_keyboard_input(action):
	if !InputMap.action_get_events(action).is_empty():
		var old_input = get_first_keyboard_input(action)
		if old_input != null:
			InputMap.action_erase_event(action, old_input) #this works if there is only one keyboard/mousebutton input per action, including ui actions



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


#func _on_preset_selected(index):
	#get_node(preset_path).select(active_preset)
	#if index != 0:
		#active_preset = index
		#$ConfirmationDialog.popup()

#func _on_ConfirmationDialog_confirmed():
	#get_node(preset_path).select(active_preset)
	#match active_preset:
		#1: set_preset(preset_classic)
		#2: set_preset(preset_mouse)
		#3: set_preset(preset_onehand)

#func set_preset(preset):
	#for k in preset.keys():
		##Delete key of pressed button
		#if !InputMap.action_get_events(k).is_empty():
			#var old_input = _get_first_valid_input(k)
			#if old_input:
				#InputMap.action_erase_event(k, old_input)
#
		##Add new key
		#var new_input
		#if preset[k] <= 10: #TODO: not a great way to determine if a key enum is a key or mouse
			#new_input = InputEventMouseButton.new()
			#new_input.button_index = preset[k]
		#else:
			#new_input = InputEventKey.new()
			#new_input.keycode = preset[k]
		#InputMap.action_add_event(k, new_input)
#
#
		##Alias action
		#var alias_action_string
		#match k:
			#"move_left": alias_action_string = "ui_left"
			#"move_right": alias_action_string = "ui_right"
			#"look_up": alias_action_string = "ui_up"
			#"look_down": alias_action_string = "ui_down"
#
		#if alias_action_string:
			#if !InputMap.action_get_events(alias_action_string).is_empty():
				#var old_input = _get_first_valid_input(alias_action_string)
				#if old_input:
					#InputMap.action_erase_event(alias_action_string, old_input)
			#InputMap.action_add_event(alias_action_string, new_input)
#
#
	#save_input_map()
	#_set_keys()



### SIGNALS ###

func input_button_focus_entered(button):
	tween_in_button_panel(button.get_parent().get_child(0))

func input_button_focus_exited(button):
	tween_out_button_panel(button.get_parent().get_child(0))

func on_confirm():
	am.play("ui_save")
	confirm_action_keyboard_input()

#func on_reset():
	#set_preset(1)

func on_return():
	w.get_node("MenuLayer/Options").exit()

### UI ###

func do_focus():
	get_node(ui_focus).grab_focus()
