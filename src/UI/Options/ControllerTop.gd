extends TextureRect


func _input(event):
	if event is InputEventJoypadButton:
		var button_frame = 0
		if event.is_pressed():
			button_frame = 1
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER:
				%BumperLeft.frame = button_frame
			JOY_BUTTON_RIGHT_SHOULDER:
				%BumperRight.frame = button_frame

	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_TRIGGER_LEFT:
				display_trigger(%TriggerLeft)
			JOY_AXIS_TRIGGER_RIGHT:
				display_trigger(%TriggerRight)


func display_trigger(trigger):
	var strength = 0.0
	match trigger.name:
		"TriggerLeft":
			strength = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT)
		"TriggerRight":
			strength = Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT)

	if strength > 0.95:
		trigger.frame = 1
	else:
		trigger.frame = 0
