#Skeleton of an input system to be filled with real systems later
extends Node
var analogstick:Vector2 = Vector2(0,0)


var Xaxis_deadzone:float = 0.2 #general deadzone
var Yaxis_deadzone:float = 0.2 #general deadzone

var Y_axis_shoot_deadzone:float = 0.25


var X_axis_1clamp_zone:float = 0.75 #values after this will equal to 1.0 in running/drifting
var pressbuffer:int = 4


func rawstick() -> Vector2:
	var outputX:float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var outputY:float = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	return Vector2(outputX,outputY)

func stick_deadzone(stick:Vector2,deadzoneX:float=Xaxis_deadzone,deadzoneY:float=Yaxis_deadzone) -> Vector2:
	var result:Vector2 = stick
	if abs(result.x) < deadzoneX: result.x = 0.0
	if abs(result.y) < deadzoneY: result.y = 0.0
	return result








##process
func _physics_process(delta):
	analogstick = stick_deadzone(rawstick())



##Presets
