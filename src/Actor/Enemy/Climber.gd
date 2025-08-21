extends Enemy

const ARM = preload("res://src/Actor/Enemy/ClimberArm.tscn")

@export var climb_dir = "cw"
@export var arm_count: int = 6
@export var arm_radius = 16
@export var arm_angle_speed = 0.01

var pivot
var pivot_pos
var pivot_index
#var pivot_cooldown_time = 0.01
var rotation_cycle = 0


func setup():
	hp = 16
	damage_on_contact = 3
	reward = 3
	speed = Vector2(80, 80) #chase speed
	setup_arms()
	change_state("rotate")


func setup_arms(): #index 0 is always to the left side, consider that when flipping, THIS IS ALSO USED IN ROTATE CODE
	var arm_index = 0
	
	for n in arm_count:
		var arm = ARM.instantiate()
		$Arms.add_child(arm)
		arm.index = arm_index
		arm.get_node("Label").text = str(arm_index)
		arm.get_node("WorldDetector").connect("body_entered", Callable(self, "on_arm_body_entered").bind(arm))
		arm.position = Vector2(arm_radius, 0).rotated((get_arm_angular_distance() * arm.index) + PI) #add pi to the rotation to add 180 degrees since it wont work otherwise
		
		if arm_index == 0:
			pivot = arm
			pivot_pos = arm.global_position
			pivot_index = pivot.index
		arm_index += 1


### STATES ###

#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("debug_level_up"):
		#pivot = arms[(arms.find(pivot) - 1) % arms.size()] #next arm
		#pivot_pos = pivot.global_position
		#rotation_cycle -= 2 * PI / arm_count

func do_rotate():
	if debug:
		for a in $Arms.get_children():
			a.modulate = Color.WHITE
			pivot.modulate = Color.RED

	if climb_dir == "cw": rotation_cycle += arm_angle_speed
	elif climb_dir == "ccw": rotation_cycle -= arm_angle_speed
	global_position = pivot_pos + Vector2(cos(rotation_cycle), sin(rotation_cycle)) * arm_radius
	
	for arm in $Arms.get_children():
		arm.position = Vector2(arm_radius, 0).rotated(get_arm_angular_distance() * arm.index + rotation_cycle + fmod(2 * PI - (PI * (2.0 * pivot_index / arm_count + 1)), 2 * PI))

func do_chase():
	hp = 1
	if not pc:
		return
	var player_vector = (pc.global_position - global_position).normalized()
	velocity = calc_velocity(velocity, player_vector, speed)
	move_and_slide()

func do_fall():
	velocity = calc_velocity(velocity, Vector2(0,0), speed, true)
	move_and_slide()

func exit_fall():
	velocity = Vector2.ZERO

### HELPERS ###

func get_arm_angular_distance() -> float:
	return (2 * PI) / float(arm_count)



### SIGNALS ###

func on_arm_body_entered(_body, arm):
	change_state("rotate")
	var old_pivot_index = pivot_index
	pivot = arm
	pivot_pos = arm.global_position
	pivot_index = arm.index
	
	var arm_index_difference = fposmod(old_pivot_index - pivot_index, arm_count)
	rotation_cycle -= (2 * PI / arm_count) * arm_index_difference


func _on_GroundDetector_body_entered(_body):
	if state == "fall":
		for a in $Arms.get_children(): 
			a.die()
		change_state("chase")
