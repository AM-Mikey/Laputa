extends TextureRect


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
