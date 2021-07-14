extends Control



var compass_distance = 8

onready var face_button_left = $MarginContainer/VBoxContainer/FrontBack/FaceButtonLeft
onready var face_button_right = $MarginContainer/VBoxContainer/FrontBack/FaceButtonRight
onready var face_button_top = $MarginContainer/VBoxContainer/FrontBack/FaceButtonTop
onready var face_button_bottom = $MarginContainer/VBoxContainer/FrontBack/FaceButtonBottom

onready var screw_left = $MarginContainer/VBoxContainer/FrontBack/ScrewLeft
onready var screw_right = $MarginContainer/VBoxContainer/FrontBack/ScrewRight

onready var bumper_left = $MarginContainer/VBoxContainer/TopBack/BumperLeft
onready var bumper_right = $MarginContainer/VBoxContainer/TopBack/BumperRight
onready var trigger_left = $MarginContainer/VBoxContainer/TopBack/TriggerLeft
onready var trigger_right = $MarginContainer/VBoxContainer/TopBack/TriggerRight

onready var stick_left = $MarginContainer/VBoxContainer/FrontBack/StickLeft
onready var stick_right = $MarginContainer/VBoxContainer/FrontBack/StickRight

onready var compass_crosshair = $MarginContainer/VBoxContainer/FrontBack/Compass/CompassCrosshair

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _process(delta):
	if Input.is_joy_button_pressed(0, JOY_DS_Y):
		face_button_left.frame = 1
	else: face_button_left.frame = 0
	if Input.is_joy_button_pressed(0, JOY_DS_A):
		face_button_right.frame = 1
	else: face_button_right.frame = 0
	if Input.is_joy_button_pressed(0, JOY_DS_X):
		face_button_top.frame = 1
	else: face_button_top.frame = 0
	if Input.is_joy_button_pressed(0, JOY_DS_B):
		face_button_bottom.frame = 1
	else: face_button_bottom.frame = 0

	if Input.is_joy_button_pressed(0, JOY_SELECT):
		if screw_left.frame < 3:
			screw_left.frame += 1
	else: 
		if screw_left.frame > 0:
			screw_left.frame -= 1
	if Input.is_joy_button_pressed(0, JOY_START):
		if screw_right.frame < 3:
			screw_right.frame += 1
	else: 
		if screw_right.frame > 0:
			screw_right.frame -= 1

	if Input.is_joy_button_pressed(0, JOY_L):
		bumper_left.frame = 1
	else: bumper_left.frame = 0
	if Input.is_joy_button_pressed(0, JOY_R):
		bumper_right.frame = 1
	else: bumper_right.frame = 0
	if Input.is_joy_button_pressed(0, JOY_L2):
		trigger_left.frame = 1
	else: trigger_left.frame = 0
	if Input.is_joy_button_pressed(0, JOY_R2):
		trigger_right.frame = 1
	else: trigger_right.frame = 0
	
	if Input.is_joy_button_pressed(0, JOY_L3):
		stick_left.frame = 1
	else: stick_left.frame = 0
	if Input.is_joy_button_pressed(0, JOY_R3):
		stick_right.frame = 1
	else: stick_right.frame = 0
	
	if Input.is_joy_button_pressed(0, JOY_DPAD_LEFT):
		if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
			compass_crosshair.position = Vector2(-1, -1) * compass_distance
		elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
			compass_crosshair.position = Vector2(-1, 1) * compass_distance
		else:
			compass_crosshair.position = Vector2.LEFT * compass_distance
	elif Input.is_joy_button_pressed(0, JOY_DPAD_RIGHT):
		if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
			compass_crosshair.position = Vector2(1, -1) * compass_distance
		elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
			compass_crosshair.position = Vector2(1, 1) * compass_distance
		else:
			compass_crosshair.position = Vector2.RIGHT * compass_distance
	elif Input.is_joy_button_pressed(0, JOY_DPAD_UP):
		compass_crosshair.position = Vector2.UP * compass_distance
	elif Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
		compass_crosshair.position = Vector2.DOWN * compass_distance
	else:
		compass_crosshair.position = Vector2.ZERO
