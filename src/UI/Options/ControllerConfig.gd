extends Control

#const BUTTON_PROMPT_FLOATING = preload("res://assets/UI/ButtonPromptFloating.png")

enum TooltipIconType {GENERIC, NINTENDO, XBOX, PLAYSTATION}
var tooltip_icon_type : TooltipIconType
var after_settings_ready = false #dont set settings unless this is true

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
@onready var settings = get_parent().get_node("Settings")
@onready var rm = %RemapManager
@onready var action_selections = %ActionSelections
@onready var tooltip_icon_type_node = %TooltipIconType
@onready var jump_on_hold_node = %JumpOnHold
@onready var return_node = %Return



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
	check_disable_d_pad()
	var display_mode_popup_menu = %TooltipIconType.get_node("OptionButton").get_child(0, true) #needed for any popup menus
	display_mode_popup_menu.canvas_item_default_texture_filter = 0 #nearest


func check_disable_analog():
	var input_left = InputEventJoypadMotion.new()
	input_left.axis = JOY_AXIS_LEFT_X
	input_left.axis_value = -1.0
	%DisableAnalog.get_node("CheckBox").button_pressed = InputMap.action_has_event("move_left", input_left)

func check_disable_d_pad():
	var input_left = InputEventJoypadButton.new()
	input_left.button_index = JOY_BUTTON_DPAD_LEFT
	%DisableDPad.get_node("CheckBox").button_pressed = InputMap.action_has_event("move_left", input_left)


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

func set_action_button_icons(temp = false):
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
	var y_pos = tooltip_icon_type * 16
	if is_active:
		out.atlas = load("res://assets/UI/ButtonPromptFloatingRed.png")
	else:
		out.atlas = load("res://assets/UI/ButtonPromptFloating.png")
	match input[0]:
		"joy":
			out.region = Rect2(input_icon_joy[int(input[1])] * 16, y_pos, 16, 16)
		"joy_analog":
			out.region = Rect2(input_icon_joy_analog[int(input[1])] * 16, y_pos, 16, 16)
	return out

### SIGNALS ###

func input_button_focus_entered(button):
	rm.tween_in_button_panel(button.get_parent().get_child(0))

func input_button_focus_exited(button):
	rm.tween_out_button_panel(button.get_parent().get_child(0))

func on_confirm():
	am.play("save")
	rm.confirm_action_input("controller")

func on_reset():
	var dir = DirAccess.open("user://")
	dir.remove("user://inputmap.json")
	rm.load_input_map(rm.default_input_map_path)
	rm.save_input_map(rm.input_map_path)
	rm.reset_temp_action_input()
	set_action_button_icons()

func on_return():
	w.get_node("MenuLayer/Options").process_exit()

### UI ###

func do_focus():
	get_node(ui_focus).grab_focus()

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


func on_disable_d_pad(toggled_on: bool):
	var input_left = InputEventJoypadButton.new()
	input_left.button_index = JOY_BUTTON_DPAD_LEFT
	var input_right = InputEventJoypadButton.new()
	input_right.button_index = JOY_BUTTON_DPAD_RIGHT
	var input_up = InputEventJoypadButton.new()
	input_up.button_index = JOY_BUTTON_DPAD_UP
	var input_down = InputEventJoypadButton.new()
	input_down.button_index = JOY_BUTTON_DPAD_DOWN

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

func on_tooltip_icon_type_selected(index: int):
	match index:
		0:
			tooltip_icon_type = TooltipIconType.GENERIC
		1:
			tooltip_icon_type = TooltipIconType.NINTENDO
		2:
			tooltip_icon_type = TooltipIconType.XBOX
		3:
			tooltip_icon_type = TooltipIconType.PLAYSTATION

	if after_settings_ready and !w.get_node("MenuLayer/Options").ishidden:
		set_action_button_icons(false)
		settings.save_setting("TooltipIconType", index)


func on_jump_on_hold_toggled(toggled_on: bool):
	if after_settings_ready and !w.get_node("MenuLayer/Options").ishidden:
		inp.buttonconfig.holdjumping = toggled_on
		settings.save_setting("JumpOnHold", toggled_on)
		settings.key_config.match_jump_on_hold_toggled(toggled_on)

func match_jump_on_hold_toggled(toggled_on: bool):
	%JumpOnHold.get_child(0).set_pressed_no_signal(toggled_on)
