extends Enemy

const ARM = preload("res://src/Actor/Enemy/ClimberArm.tscn")

@export var climb_dir = "cw"
@export var arm_count: int = 2
@export var arm_radius = 32

var pivot
var pivot_pos
var pivot_cooldown_time = 0.1
var rotation_cycle = 0
var arm_angle_speed = 0.01

func setup():
	setup_arms()
	change_state("rotate")


func setup_arms():
	var arm_index = 0
	
	for n in arm_count:
		var arm = ARM.instantiate()
		$Arms.add_child(arm)
		
		arm.index = arm_index
		arm.get_node("WorldDetector").connect("body_entered", Callable(self, "on_arm_body_entered").bind(arm))
		
		arm.position = Vector2(arm_radius, 0).rotated((get_arm_angular_distance() * arm.index) + PI) #add pi to the rotation to add 180 degrees since it wont work otherwise
		
		if arm_index == 0:
			pivot = arm
			pivot_pos = arm.global_position
			if debug:
				pivot.modulate = Color.RED
		arm_index += 1


#func replace_arms(dead_arm_index):
	#collision_disabled = true
	#
	#var arm_index
	#if dead_arm_index != pivot.index:
		#arm_index = 1
	#else:
		#arm_index = 0
		#
	#for a in get_children():
		#if "part_type" in a:
			#if a.part_type == "arm" and a != pivot and not a.dead:
				#a.index = arm_index
				#
				#var new_pos = Vector2(arm_radius, 0.0).rotated((get_arm_angle_offset() * a.index) + PI)
				#var tween = get_tree().create_tween()
				#tween.tween_property(a, "position", new_pos, 0.4).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
				#
				#arm_index += 1
			#elif a.part_type == "arm" and a == pivot and not a.dead:
				#a.index = 0
	#
	#await get_tree().create_timer(0.4).timeout
	#collision_disabled = false



### STATES ###


func do_rotate():
	rotation_cycle += arm_angle_speed
	#print("rotcyc: ", rotation_cycle)
	$Sprite2D2.global_position = pivot_pos
	global_position = pivot_pos + Vector2(cos(rotation_cycle), sin(rotation_cycle)) * arm_radius
	#$Arms.rotation += arm_angle_speed
	
	for arm in $Arms.get_children():
		arm.position = Vector2(arm_radius, 0).rotated((get_arm_angular_distance() * arm.index) + PI + rotation_cycle)





### HELPERS ###

func get_arm_angular_distance() -> float:
	return (2 * PI) / float(arm_count)
	

### SIGNALS ###

func on_arm_body_entered(_body, arm): #doesnt seem to work if touched arm is the second one
	var next_arm_index = 3 if climb_dir == "cw" else 1
	if arm.index != next_arm_index: #next arm	#by limiting it to getting the next arm we avoid the problem with getting stuck in a corner, but the pattern is less interesting and it tends to stay in one place more often
		return
	if $PivotCooldown.is_stopped():
		$PivotCooldown.start(pivot_cooldown_time)
		#var _old_pivot_pos = pivot_pos
		pivot = arm
		pivot_pos = arm.global_position
		rotation_cycle +=  2 * PI - get_arm_angular_distance()
