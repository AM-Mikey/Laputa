extends Enemy



var pivot = "arm"
onready var pivot_pos = $Arm.position

export var climb_dir = "cw"


var arm_angle = 0
var arm_angle2 = 0
var arm_distance = 32
var arm_angle_speed = 0.01

var arm_angle_distance = PI


func _ready():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(60, 60)
	acceleration = 25
	level = 3



func _physics_process(delta):
	$Body.position = ($Arm.position + $Arm2.position) /2
	
	match pivot:
#		"body":
#			arm_angle += arm_angle_speed
#			arm_angle2 += arm_angle_speed
#			$Arm.position = Vector2(cos(arm_angle), sin(arm_angle)) * arm_distance
#			$Arm2.position = Vector2(cos(arm_angle2), sin(arm_angle2)) * arm_distance
		"arm":
			
			arm_angle2 += arm_angle_speed
			#var old_arm_pos = $Arm.global_position
			
			#$Body.position = Vector2(cos(arm_angle), sin(arm_angle)) * arm_distance
			$Arm2.position = pivot_pos + Vector2(cos(arm_angle2), sin(arm_angle2)) * arm_distance 
			#$Arm.global_position = old_arm_pos
		"arm2":
			
			arm_angle += arm_angle_speed
			
			#var old_arm_pos2 = $Arm2.global_position
			#$Body.position = Vector2(cos(arm_angle), sin(arm_angle)) * arm_distance
			$Arm.position = pivot_pos + Vector2(cos(arm_angle), sin(arm_angle)) * arm_distance
			#$Arm2.global_position = old_arm_pos2

func _on_Arm_body_entered(body):
	print("attached")
	pivot = "arm"
	pivot_pos = $Arm.position
	arm_angle2 = arm_angle + arm_angle_distance


func _on_Arm2_body_entered(body):
	print("attached")
	pivot = "arm2"
	pivot_pos = $Arm2.position
	arm_angle = arm_angle2 + arm_angle_distance
