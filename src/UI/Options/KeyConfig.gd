extends Control

var after_settings_ready = false #dont set settings unless this is true

@export var ui_focus: NodePath
@export var preset_path: NodePath

@onready var w = get_tree().get_root().get_node("World")
@onready var settings = get_parent().get_node("Settings")
@onready var rm = $RemapManager
@onready var action_selections = %ActionSelections
@onready var return_node = %Return


#TODO: continue transferring things over to RemapManager

func _ready():
	for action_box in %ActionSelections.get_children():
		rm.action_buttons[action_box.name] = action_box.get_child(1)
	for b in rm.action_buttons.values():
		b.connect("pressed", Callable(self, "input_button_pressed").bind(b))
		b.connect("focus_entered", Callable(self, "input_button_focus_entered").bind(b))
		b.connect("focus_exited", Callable(self, "input_button_focus_exited").bind(b))
	set_button_text()
	rm.setup_action_button_panels()



### CHANGING ACTION INPUT ###

func input_button_pressed(button): #test this ignore
	rm.current_listening_action = rm.action_buttons.find_key(button)
	#if ignore_button_press:
		#ignore_button_press = false
		#button.set_pressed(false)
	#else:
	for i in rm.action_buttons.values(): #deselect all other buttons
		if i != button:
			i.set_pressed(false)


func _input(event):
	if (event is InputEventKey) and rm.current_listening_action != null: #or event is InputEventMouseButton #TODO implement mouseaskey
		get_viewport().set_input_as_handled()
		rm.set_temp_action_input(event, "keyboard")
		rm.current_listening_action = null

		#non issue, buttons only work on click right now
		#var accept_input_event = _get_first_valid_input("ui_accept") #prevent us from entering another assignment mode when event is accept_event
		#if event is InputEventKey and accept_input_event is InputEventKey:
			#if event.keycode == accept_input_event.keycode:
				#ignore_button_press = true
		#if event is InputEventMouseButton and accept_input_event is InputEventMouseButton:
			#if event.button_index == accept_input_event.button_index:
				#ignore_button_press = true


func set_button_text(temp = false):
	if temp:
		var active_button = rm.action_buttons[rm.current_listening_action]
		active_button.add_theme_color_override("font_color", rm.button_text_color_temp)
		active_button.add_theme_color_override("font_focus_color", rm.button_text_color_temp)
		active_button.add_theme_color_override("font_pressed_color", rm.button_text_color_temp)
		active_button.add_theme_color_override("font_hover_color", rm.button_text_color_temp)
		active_button.add_theme_color_override("font_hover_pressed_color", rm.button_text_color_temp)

	for button in rm.action_buttons.values():
		if !temp:
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_focus_color")
			button.remove_theme_color_override("font_pressed_color")
			button.remove_theme_color_override("font_hover_color")
			button.remove_theme_color_override("font_hover_pressed_color")

		var action = rm.action_buttons.find_key(button)
		var input
		if temp:
			input = rm.temp_action_keyboard_input[action]
		else:
			input = rm.convert_input_event_to_array(rm.get_action_input_event(action, "keyboard"))

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
	rm.tween_in_button_panel(button.get_parent().get_child(0))

func input_button_focus_exited(button):
	rm.tween_out_button_panel(button.get_parent().get_child(0))

func on_confirm():
	am.play("save")
	rm.confirm_action_input("keyboard")

func on_reset():
	var dir = DirAccess.open("user://")
	dir.remove("user://inputmap.json")
	rm.load_input_map(rm.default_input_map_path)
	rm.save_input_map(rm.input_map_path)
	rm.reset_temp_action_input()
	set_button_text()



func on_return():
	w.get_node("MenuLayer/Options").process_exit()

### UI ###

func do_focus():
	get_node(ui_focus).grab_focus()


func on_jump_on_hold_toggled(toggled_on: bool):
	if after_settings_ready and !w.get_node("MenuLayer/Options").ishidden:
		inp.buttonconfig.holdjumping = toggled_on
		settings.save_setting("JumpOnHold", toggled_on)
		settings.controller_config.match_jump_on_hold_toggled(toggled_on)

func match_jump_on_hold_toggled(toggled_on: bool):
	%JumpOnHold.set_pressed_no_signal(toggled_on)
