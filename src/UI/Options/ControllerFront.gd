extends TextureRect

@onready var stick_left_home_pos = %StickLeft.global_position
@onready var stick_right_home_pos = %StickRight.global_position

#func _physics_process(_delta):
	#

func _input(event):
	if event is InputEventJoypadButton:
		var button_frame = 0
		if event.is_pressed():
			button_frame = 1
		match event.button_index:
			JOY_BUTTON_X:
				%FaceButtonLeft.frame = button_frame
			JOY_BUTTON_B:
				%FaceButtonRight.frame = button_frame
			JOY_BUTTON_Y:
				%FaceButtonUp.frame = button_frame
			JOY_BUTTON_A:
				%FaceButtonDown.frame = button_frame
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
				display_d_pad()
			JOY_BUTTON_BACK:
				%Select.frame = button_frame
			JOY_BUTTON_START:
				%Start.frame = button_frame
	if event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y: display_stick(%StickLeft)
			JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y: display_stick(%StickRight)


func display_d_pad():
	var strength_x = 0
	var strength_y = 0
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
		strength_x -= 1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
		strength_x += 1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
		strength_y -= 1
	if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
		strength_y += 1
	var dir = Vector2i(strength_x, strength_y)
	var d_pad_frame = 0
	match dir:
		Vector2i(0, 0): d_pad_frame = 0
		Vector2i(1, 0): d_pad_frame = 1
		Vector2i(-1, 0): d_pad_frame = 2
		Vector2i(0, -1): d_pad_frame = 3
		Vector2i(0, 1): d_pad_frame = 4
		Vector2i(-1, -1): d_pad_frame = 5
		Vector2i(1, -1): d_pad_frame = 6
		Vector2i(-1, 1): d_pad_frame = 7
		Vector2i(1, 1): d_pad_frame = 8
	%DPad.frame = d_pad_frame

func display_stick(stick):
	var stick_home_pos: Vector2
	var strength_x = 0.0
	var strength_y = 0.0
	match stick.name:
		"StickLeft":
			strength_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
			strength_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
			stick_home_pos = stick_left_home_pos
		"StickRight":
			strength_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
			strength_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
			stick_home_pos = stick_right_home_pos

	var dir = Vector2(strength_x, strength_y)
	var deg = rad_to_deg(fposmod(dir.rotated(0.5 * PI).angle(), 2 * PI))

	if dir.length() >= 0.95:
		var stick_frame = 0
		if (deg >= 345 && deg <= 360) || (deg >= 0 && deg < 15):
			stick_frame = 1
		elif deg >= 15 && deg < 45:
			stick_frame = 2
		elif deg >= 45 && deg < 75:
			stick_frame = 3
		elif deg >= 75 && deg < 105:
			stick_frame = 4
		elif deg >= 105 && deg < 135:
			stick_frame = 5
		elif deg >= 135 && deg < 165:
			stick_frame = 6
		elif deg >= 165 && deg < 195:
			stick_frame = 7
		elif deg >= 195 && deg < 225:
			stick_frame = 8
		elif deg >= 225 && deg < 255:
			stick_frame = 9
		elif deg >= 255 && deg < 285:
			stick_frame = 10
		elif deg >= 285 && deg < 315:
			stick_frame = 11
		elif (deg >= 315 && deg < 345):
			stick_frame = 12
		stick.frame = stick_frame
		stick.position = stick_home_pos
	else:
		stick.frame = 0
		stick.position = stick_home_pos + Vector2(strength_x * 8, strength_y * 8)
