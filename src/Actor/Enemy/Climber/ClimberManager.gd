extends Node2D

const ARM = preload("res://src/Actor/Enemy/Climber/ClimberArm.tscn")


var pivot
var pivot_pos
@onready var body = $ClimberBody

var rotation_cycle = 0


@export var climb_dir = "cw"
@export var arm_count: int = 2



@export var arm_distance = 64
var arm_angle_speed = 0.01

var collision_disabled = false

func _ready():
	setup_arms()

func get_arm_angle_offset() -> float:
	return (2 * PI) / float(arm_count)

func setup_arms():
	var arm_index = 0
	
	for n in arm_count:
		var arm = ARM.instantiate()
		add_child(arm)
		
		arm.index = arm_index
		arm.get_node("WorldDetector").connect("body_entered", Callable(self, "on_arm_body_entered").bind(arm))
		
		arm.position = Vector2(arm_distance/2, 0).rotated((get_arm_angle_offset() * arm.index) + PI) #add pi to the rotation to add 180 degrees since it wont work otherwise
		
		if arm_index == 0:
			pivot = arm
			pivot.modulate = Color.RED
			pivot_pos = arm.global_position
		arm_index += 1

func replace_arms(dead_arm_index):
	collision_disabled = true
	
	var arm_index
	if dead_arm_index != pivot.index:
		arm_index = 1
	else:
		arm_index = 0
		
	for a in get_children():
		if "part_type" in a:
			if a.part_type == "arm" and a != pivot and not a.dead:
				a.index = arm_index
				
				var new_pos = Vector2(arm_distance/2.0, 0.0).rotated((get_arm_angle_offset() * a.index) + PI)
				var tween = get_tree().create_tween()
				tween.tween_property(a, "position", new_pos, 0.4).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
				
				arm_index += 1
			elif a.part_type == "arm" and a == pivot and not a.dead:
				a.index = 0
	
	await get_tree().create_timer(0.4).timeout
	collision_disabled = false
	

func _physics_process(_delta):
	rotation_cycle += arm_angle_speed
	global_position = pivot_pos + Vector2(cos(rotation_cycle), sin(rotation_cycle)) * arm_distance /2
	rotation += arm_angle_speed



func on_arm_body_entered(_body, arm):
	if not collision_disabled:
		if $PivotCooldown.time_left == 0:
			$PivotCooldown.start(0.1)
			print("attached with: " + str(arm))
			var _old_pivot_pos = pivot_pos
			pivot = arm
			pivot_pos = arm.global_position
			rotation_cycle +=  2 * PI - get_arm_angle_offset()
