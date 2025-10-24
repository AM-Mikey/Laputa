#Skeleton of an input system to be filled with real systems later
extends Node

var Y_axis_shoot_deadzone:float = 0.25

var pressbuffer:int = 4


func inputpressed(button:String,custombuffer:int=pressbuffer,deadzone_min:float=0.8) -> bool:
	#replace with real buffer check later
	if Input.get_action_strength(button) >= deadzone_min and Input.is_action_just_pressed(button):
		return true
	return false

func inputheld(button:String,deadzone_min:float=0.8,below:int=900000000,above:int=0) -> bool: #button held. pretty simple
	#replace with real buffer check
	if Input.get_action_strength(button) >= deadzone_min:
		return true
	return false





##Presets

func check_gunaim(button) -> bool:
	inputheld(button,Y_axis_shoot_deadzone)
	return false
