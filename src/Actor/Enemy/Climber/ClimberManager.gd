extends Node2D

const ARM = preload("res://src/Actor/Enemy/Climber/ClimberArm.tscn")


var pivot
onready var body = $ClimberBody

export var climb_dir = "cw"
export var arm_count: int = 2



var arm_distance = 32
var arm_angle_speed = 0.01
onready var arm_angle_offset = (2 * PI) / arm_count #how did this work for 3 arms? #PI / arm_count #2 * PI / arm_count - 1 



func _ready():
	var arm_start_angle = 0.0
	for n in arm_count:
		var arm = ARM.instance()
		add_child(arm)
		arm.get_node("WorldDetector").connect("body_entered", self, "on_arm_body_entered", [arm])
		arm.position = Vector2(arm_distance/2, 0).rotated(arm_start_angle) #useless
		arm.arm_angle = arm_start_angle
		if arm_start_angle == 0: #first
			pivot = arm

		arm_start_angle += arm_angle_offset


func _physics_process(delta):
	for c in get_children():
		if c.part_type == "body":
			var arm_positions = []
			for a in get_children():
				if a.part_type == "arm":
					arm_positions.append(a.position)

			var arm_average = Vector2.ZERO
			for p in arm_positions:
				arm_average += p
			arm_average /= arm_positions.size()

			c.position = arm_average


	var arm_start_angle = 0.0
	for c in get_children():
		if c.part_type == "arm" and c != pivot:
				c.arm_angle += arm_angle_speed
				c.global_position = pivot.global_position + Vector2(cos(c.arm_angle), sin(c.arm_angle)) * arm_distance 
				#c.position = c.position.rotated(arm_angle_speed)
				#c.position =  Vector2(arm_distance/2, 0).rotated(c.arm_angle) #pivot.global_position + Vector2(cos(c.arm_angle), sin(c.arm_angle)) * arm_distance 




func on_arm_body_entered(body, arm):
	print("attached with: " + str(arm))
	pivot = arm
	
	#var arm_start_angle = arm_angle_offset
	var number = 1
	for c in get_children():
		if c.part_type == "arm" and c != pivot:
			c.arm_angle = pivot.arm_angle + 2 * PI / arm_count - 1 * number #(2 * PI / arm_count)
			#arm_start_angle += arm_angle_offset
			number += 1
			pass
