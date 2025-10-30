#Skeleton of an input system to be filled with real systems later
extends Node
var analogstick:Vector2 = Vector2(0,0)


var Xaxis_deadzone:float = 0.2 #general deadzone
var Yaxis_deadzone:float = 0.2 #general deadzone
var Xaxis_clampzone:float = 0.75 #everything after this input is turned into 1.0

var Y_axis_shoot_deadzone:float = 0.25


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

func stick_clampzoneX(stick:Vector2,clampX:float=Xaxis_clampzone) -> Vector2:
	var result:Vector2 = stick
	if abs(result.x) >= clampX:
		result.x = sign(result.x)
	return result






##process
func _physics_process(delta):
	analogstick = stick_clampzoneX( stick_deadzone(rawstick()) )
	print (analogstick)


##Presets
