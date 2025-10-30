#Skeleton of an input system to be filled with real systems later
extends Node

			#STICK
var analogstick:Vector2 = Vector2(0,0)
var Xaxis_deadzone:float = 0.2 #general deadzone
var Yaxis_deadzone:float = 0.2 #general deadzone
var Xaxis_clampzone:float = 0.85 #everything after this input is turned into 1.0

var Y_axis_shoot_deadzone:float = 0.25

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


			#####BUFFER


##A button needs to be added to this to be bufferable
var buffer:Array=[
	["look_up",0,9000,9000],
	["look_down",0,9000,9000],
	["look_left",0,9000,9000],
	["look_right",0,9000,9000],
	["jump",0,9000,9000],
	["fire_manual",0,9000,9000],
	["fire_automatic",0,9000,9000],
	["inspect",0,9000,9000],
	["inventory",0,9000,9000],
	]

var inputstrength:float = 0.5 #for assigning buttons to analog sticks
var pressbuffer:int = 4

func base_inputheld(button:String) -> bool:
	if Input.get_action_strength(button) >= inputstrength:
		return true
	else:
		return false

func writebuffer() -> void:
	for x in buffer:
		x[2]+=1
		x[3]+=1
		if base_inputheld(x[0]) and x[1] == 0:
			x[2]=0
		if base_inputheld(x[0]):
			x[1]+=1
		if not base_inputheld(x[0]) and x[1] != 0:
			x[1]=0
			x[3]=0



func pressed(button,custombuffer=pressbuffer,prevstate='') -> bool: 
	for x in buffer:
		if x[0] == button:
			if x[2] <= custombuffer:
				x[2] = custombuffer
				return true 
			else: return false
	print ("INPUT NOT FOUND IN BUFFER")
	return false



##process
func _physics_process(delta):
	analogstick = stick_clampzoneX( stick_deadzone(rawstick()) )

	writebuffer()
##Presets
