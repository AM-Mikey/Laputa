extends Control



var compass_distance = 8

#onready var face_button_left = $VBoxContainer/FrontBack/FaceButtonLeft
#onready var face_button_right = $VBoxContainer/FrontBack/FaceButtonRight
#onready var face_button_top = $VBoxContainer/FrontBack/FaceButtonTop
#onready var face_button_bottom = $VBoxContainer/FrontBack/FaceButtonBottom

#onready var screw_left = $VBoxContainer/FrontBack/ScrewLeft
#onready var screw_right = $VBoxContainer/FrontBack/ScrewRight
#
#onready var bumper_left = $VBoxContainer/TopBack/BumperLeft
#onready var bumper_right = $VBoxContainer/TopBack/BumperRight
#onready var trigger_left = $VBoxContainer/TopBack/TriggerLeft
#onready var trigger_right = $VBoxContainer/TopBack/TriggerRight
#
#onready var stick_left = $VBoxContainer/FrontBack/StickLeft
#onready var stick_right = $VBoxContainer/FrontBack/StickRight
#
#onready var compass_crosshair = $VBoxContainer/FrontBack/Compass/CompassCrosshair



#func _process(delta):
#	if Input.is_joy_button_pressed(0, JOY_DS_Y):
#		face_button_left.frame = 1
#	else: face_button_left.frame = 0
#	if Input.is_joy_button_pressed(0, JOY_DS_A):
#		face_button_right.frame = 1
#	else: face_button_right.frame = 0
#	if Input.is_joy_button_pressed(0, JOY_DS_X):
#		face_button_top.frame = 1
#	else: face_button_top.frame = 0
#	if Input.is_joy_button_pressed(0, JOY_DS_B):
#		face_button_bottom.frame = 1
#	else: face_button_bottom.frame = 0
#
#	if Input.is_joy_button_pressed(0, JOY_SELECT):
#		if screw_left.frame < 3:
#			screw_left.frame += 1
#	else: 
#		if screw_left.frame > 0:
#			screw_left.frame -= 1
#	if Input.is_joy_button_pressed(0, JOY_START):
#		if screw_right.frame < 3:
#			screw_right.frame += 1
#	else: 
#		if screw_right.frame > 0:
#			screw_right.frame -= 1
#
#	if Input.is_joy_button_pressed(0, JOY_L):
#		bumper_left.frame = 1
#	else: bumper_left.frame = 0
#	if Input.is_joy_button_pressed(0, JOY_R):
#		bumper_right.frame = 1
#	else: bumper_right.frame = 0
#	if Input.is_joy_button_pressed(0, JOY_L2):
#		trigger_left.frame = 1
#	else: trigger_left.frame = 0
#	if Input.is_joy_button_pressed(0, JOY_R2):
#		trigger_right.frame = 1
#	else: trigger_right.frame = 0
#
#	if Input.is_joy_button_pressed(0, JOY_L3):
#		stick_left.frame = 1
#	else: stick_left.frame = 0
#	if Input.is_joy_button_pressed(0, JOY_R3):
#		stick_right.frame = 1
#	else: stick_right.frame = 0
#
#	if Input.is_joy_button_pressed(0, JOY_DPAD_LEFT):
#		if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
#			compass_crosshair.position = Vector2(-1, -1) * compass_distance
#		elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
#			compass_crosshair.position = Vector2(-1, 1) * compass_distance
#		else:
#			compass_crosshair.position = Vector2.LEFT * compass_distance
#	elif Input.is_joy_button_pressed(0, JOY_DPAD_RIGHT):
#		if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
#			compass_crosshair.position = Vector2(1, -1) * compass_distance
#		elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
#			compass_crosshair.position = Vector2(1, 1) * compass_distance
#		else:
#			compass_crosshair.position = Vector2.RIGHT * compass_distance
#	elif Input.is_joy_button_pressed(0, JOY_DPAD_UP):
#		compass_crosshair.position = Vector2.UP * compass_distance
#	elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
#		compass_crosshair.position = Vector2.DOWN * compass_distance
#	else:
#		compass_crosshair.position = Vector2.ZERO
