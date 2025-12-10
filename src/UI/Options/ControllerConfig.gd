extends Control

#const BUTTON_PROMPT_FLOATING = preload("res://assets/UI/ButtonPromptFloating.png")

var input_map_path = "user://inputmap.json"


var input_icon_joy = {
	JOY_BUTTON_Y: 0,
	JOY_BUTTON_B: 1,
	JOY_BUTTON_A: 2,
	JOY_BUTTON_X: 3,
	JOY_BUTTON_LEFT_SHOULDER: 6,
	JOY_BUTTON_RIGHT_SHOULDER: 7,
	JOY_BUTTON_BACK: 8,
	JOY_BUTTON_START: 9,
	JOY_BUTTON_LEFT_STICK: 10,
	JOY_BUTTON_RIGHT_STICK:11,
	JOY_BUTTON_DPAD_UP: 12,
	JOY_BUTTON_DPAD_DOWN: 13,
	JOY_BUTTON_DPAD_LEFT: 14,
	JOY_BUTTON_DPAD_RIGHT: 15,
}

var input_icon_joy_analog = {
	JOY_AXIS_TRIGGER_LEFT: 4,
	JOY_AXIS_TRIGGER_RIGHT: 5,
	JOY_AXIS_LEFT_X: 16,
	JOY_AXIS_LEFT_Y: 17,
	JOY_AXIS_RIGHT_X: 18,
	JOY_AXIS_RIGHT_Y: 19,
}

@export var ui_focus: NodePath

@onready var w = get_tree().get_root().get_node("World")
@onready var rm = $RemapManager
@onready var action_selections = %ActionSelections





func _ready():
	for action_box in %ActionSelections.get_children():
		rm.action_buttons[action_box.name] = action_box.get_child(1)
	for b in rm.action_buttons.values():
		b.connect("pressed", Callable(self, "input_button_pressed").bind(b))
		b.connect("focus_entered", Callable(self, "input_button_focus_entered").bind(b))
		b.connect("focus_exited", Callable(self, "input_button_focus_exited").bind(b))
	set_action_button_icons()
	rm.setup_action_button_panels()
	check_disable_analog()


func check_disable_analog():
	var input_left = InputEventJoypadMotion.new()
	input_left.axis = JOY_AXIS_LEFT_X
	input_left.axis_value = -1.0
	%DisableAnalog.get_node("Button").button_pressed = InputMap.action_has_event("move_left", input_left)


### CHANGING ACTION INPUT ###

func input_button_pressed(button):
	rm.current_listening_action = rm.action_buttons.find_key(button)
	for i in rm.action_buttons.values(): #deselect all other buttons
		if i != button:
			i.set_pressed(false)


func _input(event):
	if (event is InputEventJoypadButton || event is InputEventJoypadMotion) && rm.current_listening_action != null:
		get_viewport().set_input_as_handled()
		rm.set_temp_action_input(event, "controller")
		rm.current_listening_action = null



### ANIMATION ###

func set_action_button_icons(temp = false): #needs default
	if temp:
		var active_button = rm.action_buttons[rm.current_listening_action]
		rm.action_button_is_red.append(active_button)

	for button in rm.action_buttons.values():
		if !temp:
			rm.action_button_is_red.erase(button)

		var action = rm.action_buttons.find_key(button)
		var input = rm.temp_action_controller_input[action] if temp else rm.convert_input_event_to_array(rm.get_action_input_event(action, "controller"))

		if input != null:
			button.icon = get_button_texture_atlas(input, rm.action_button_is_red.has(button))

func get_button_texture_atlas(input, is_active) -> AtlasTexture:
	var out = AtlasTexture.new()
	if is_active:
		out.atlas = load("res://assets/UI/ButtonPromptFloatingRed.png")
	else:
		out.atlas = load("res://assets/UI/ButtonPromptFloating.png")
	match input[0]:
		"joy":
			out.region = Rect2(input_icon_joy[int(input[1])] * 16, 0, 16, 16)
		"joy_analog":
			out.region = Rect2(input_icon_joy_analog[int(input[1])] * 16, 0, 16, 16)
	return out

### SIGNALS ###

func input_button_focus_entered(button):
	rm.tween_in_button_panel(button.get_parent().get_child(0))

func input_button_focus_exited(button):
	rm.tween_out_button_panel(button.get_parent().get_child(0))

func on_confirm():
	am.play("save")
	rm.confirm_action_input("controller")

#func on_reset():
	#set_preset(1)

func on_return():
	w.get_node("MenuLayer/Options").exit()

### UI ###

func do_focus():
	pass
	#get_node(ui_focus).grab_focus()

### SETTINGS ###

func on_disable_analog(toggled_on: bool):
	var input_left = InputEventJoypadMotion.new()
	input_left.axis = JOY_AXIS_LEFT_X
	input_left.axis_value = -1.0
	var input_right = InputEventJoypadMotion.new()
	input_right.axis = JOY_AXIS_LEFT_X
	input_right.axis_value = 1.0
	var input_up = InputEventJoypadMotion.new()
	input_up.axis = JOY_AXIS_LEFT_Y
	input_up.axis_value = -1.0
	var input_down = InputEventJoypadMotion.new()
	input_down.axis = JOY_AXIS_LEFT_Y
	input_down.axis_value = 1.0

	if toggled_on:
		InputMap.action_add_event("move_left", input_left)
		InputMap.action_add_event("move_right", input_right)
		InputMap.action_add_event("look_up", input_up)
		InputMap.action_add_event("look_down", input_down)
	else:
		InputMap.action_erase_event("move_left", input_left)
		InputMap.action_erase_event("move_right", input_right)
		InputMap.action_erase_event("look_up", input_up)
		InputMap.action_erase_event("look_down", input_down)
	rm.save_input_map()
