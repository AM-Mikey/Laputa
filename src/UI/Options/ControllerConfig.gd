extends Control

const BUTTON_PROMPT_FLOATING = preload("res://assets/UI/ButtonPromptFloating.png")

var input_map_path = "user://inputmap.json"

var ignore_button_press = false
var current_listening_action = null
var action_buttons = {}
var action_button_panel_default_widths = {}
var action_button_panel_tween_time = 0.1
var button_text_color_temp = Color(0.988, 0.22, 0.22)

@export var ui_focus: NodePath

@onready var w = get_tree().get_root().get_node("World")
@onready var action_options = get_tree().get_nodes_in_group("ActionOptions")

#var action_dict = {
	#"": "None",
	#"jump": "Jump",
	#"fire_manual": "Fire",
	#"fire_automatic": "Autofire",
	#"inspect": "Inspect",
	#"inventory": "Inventory",
	#"gun_left": "Next Gun",
	#"gun_right": "Last Gun",
	#"pause": "Pause",
#}
#
#var button_dict = {
	#"DpadUp": JOY_BUTTON_DPAD_UP,
	#"DpadLeft": JOY_BUTTON_DPAD_LEFT,
	#"DpadRight": JOY_BUTTON_DPAD_RIGHT,
	#"DpadDown": JOY_BUTTON_DPAD_DOWN,
	#"Select": JOY_BUTTON_BACK,
	#"Start": JOY_BUTTON_START,
	#"FaceUp": JOY_BUTTON_Y,
	#"FaceLeft": JOY_BUTTON_X,
	#"FaceRight": JOY_BUTTON_B,
	#"FaceDown": JOY_BUTTON_A,
	#"L1": JOY_BUTTON_LEFT_SHOULDER,
	#"L2": JOY_AXIS_TRIGGER_LEFT,
	#"L3": JOY_BUTTON_LEFT_STICK,
	#"R1": JOY_BUTTON_RIGHT_SHOULDER,
	#"R2": JOY_AXIS_TRIGGER_RIGHT,
	#"R3": JOY_BUTTON_RIGHT_STICK,
	#}

var input_icon_order = [
	JOY_BUTTON_Y,
	JOY_BUTTON_B,
	JOY_BUTTON_A,
	JOY_BUTTON_X,
	JOY_AXIS_TRIGGER_LEFT,
	JOY_AXIS_TRIGGER_RIGHT,
	JOY_BUTTON_LEFT_SHOULDER,
	JOY_BUTTON_RIGHT_SHOULDER,
	JOY_BUTTON_BACK,
	JOY_BUTTON_START,
	JOY_BUTTON_LEFT_STICK,
	JOY_BUTTON_RIGHT_STICK,
]













func _ready():
	set_action_button_icons()

#func _ready():
	#for o in action_options:
		#for a in action_dict:
			#o.add_item(action_dict[a])
##			if o.get_signal_list().size() == 0:
			##o.connect("item_selected", self, "_set_button_action", [o.name])
	#_setup_action_options()
#
#
#func _setup_action_options():
	#for o in action_options:
		##print(o.name)
#
##		var found_action
#
		#for a in InputMap.get_actions():
			#if a in action_dict.keys():
				#for e in InputMap.action_get_events(a):
					#if e is InputEventJoypadButton:
##						print("e.button_index : " + str(e.button_index))
##						print("button_dict[o.name] : " + str(button_dict[o.name]))
						#if e.button_index == button_dict[o.name]:
							##print("YAHOO: " + o.name)
							#o.modulate = Color.AQUA
							#o.select(action_dict.keys().find(a))
##							o.selected = action_dict.keys().find(a)

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



#func load_input_map(): #called on save system load options
	#var data
	#if !FileAccess.file_exists(input_map_path):
		#printerr("ERROR: could not load input map data")
		#return
	#var file = FileAccess.open(input_map_path, FileAccess.READ)
	#if !file:
		#return
	#var text = file.get_as_text()
	#var test_json_conv = JSON.new()
	#test_json_conv.parse(text)
	#data = test_json_conv.get_data()
	#file.close()
#
	#set_button_icons(data)
#
	#for a in data.keys():
		#InputMap.action_erase_events(a) #does this overwrite all events period?
		#for i in data[a]:
			#var new_input
			#match i.front():
				#"mouse":
					#new_input = InputEventMouseButton.new()
					#new_input.set_button_index(i.back())
				#"key":
					#new_input = InputEventKey.new()
					#new_input.set_keycode(i.back())
				#"joy":
					#new_input = InputEventJoypadButton.new()
					#new_input.set_button_index(i.back())
#
			#InputMap.action_add_event(a, new_input)



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


func set_action_button_icons():
	var data
	if !FileAccess.file_exists(input_map_path):
		printerr("ERROR: could not load input map data")
		return
	var file = FileAccess.open(input_map_path, FileAccess.READ)
	if !file:
		return
	var text = file.get_as_text()
	var test_json_conv = JSON.new()
	test_json_conv.parse(text)
	data = test_json_conv.get_data()
	file.close()

	for action in data.keys():
		match action:
			"jump":
				set_action_button_icon_to_texture(data, action, %JumpButton)
			"fire_manual":
				set_action_button_icon_to_texture(data, action, %FireManualButton)
			"fire_automatic":
				set_action_button_icon_to_texture(data, action, %FireAutomaticButton)
			"gun_left":
				set_action_button_icon_to_texture(data, action, %GunLeftButton)
			"gun_right":
				set_action_button_icon_to_texture(data, action, %GunRightButton)
			"inventory":
				set_action_button_icon_to_texture(data, action, %InventoryButton)
			"pause":
				set_action_button_icon_to_texture(data, action, %PauseButton)

func set_action_button_icon_to_texture(data, action, button):
	for i in data[action]:
		if i[0] == "joy" || i[0] == "joy_analog": #is a joystick input
			var icon_texture = AtlasTexture.new()
			icon_texture.atlas = BUTTON_PROMPT_FLOATING
			icon_texture.region = Rect2(input_icon_order.find(int(i[1])) * 16, 0, 16, 16)
			button.icon = icon_texture

### SIGNALS ###

func input_button_focus_entered(button):
	tween_in_button_panel(button.get_parent().get_child(0))

func input_button_focus_exited(button):
	tween_out_button_panel(button.get_parent().get_child(0))

#func on_confirm():
	#am.play("ui_save")
	#confirm_action_controller_input()

#func on_reset():
	#set_preset(1)

func on_return():
	w.get_node("MenuLayer/Options").exit()

### UI ###

func do_focus():
	pass
	#get_node(ui_focus).grab_focus()
