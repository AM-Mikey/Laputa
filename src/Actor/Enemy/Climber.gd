extends Enemy

const ICON = preload("res://assets/Actor/Enemy/ClimberIcon.png")
const ARM = preload("res://src/Actor/Enemy/ClimberArm.tscn")

@export var climb_dir = "cw"
@export var arm_count: int = 6
@export var arm_radius = 16
@export var arm_angle_speed = 0.01
@export var rotate_stop_time: float = 1.5
@export var difficulty: int = 0


var pivot
var pivot_pos
var pivot_index

var rotation_cycle = 0

var curr_rotate_angle: float = 0.0
var tolerate_angle: float = 0.5

var linear_momentum := Vector2.ZERO


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
		arm.arm_die.connect(on_arm_die)
		arm.position = Vector2(arm_radius, 0).rotated((get_arm_angular_distance() * arm.index) + PI) #add pi to the rotation to add 180 degrees since it wont work otherwise

		if arm_index == 0:
			pivot = arm
			pivot_pos = arm.global_position
			pivot_index = pivot.index
		arm_index += 1

func calc_velocity(_move_dir, _do_gravity = true, _do_acceleration = true, _do_friction = true) -> Vector2:
	var out: = velocity
	var fractional_mod = 1.0 if !is_in_water else 0.666

	out *= fractional_mod

	#Y
	out.y += gravity * get_physics_process_delta_time()
	return out

### STATES ###

func enter_rotate(_prev_state):
	if (difficulty == 0):
		curr_rotate_angle = 0.0

func do_rotate(delta):
	if debug:
		for a in $Arms.get_children():
			a.modulate = Color.WHITE
			if (pivot):
				pivot.modulate = Color.RED

	if climb_dir == "cw": rotation_cycle += arm_angle_speed
	elif climb_dir == "ccw": rotation_cycle -= arm_angle_speed
	var new_global_position: Vector2 = pivot_pos + Vector2(cos(rotation_cycle), sin(rotation_cycle)) * arm_radius
	linear_momentum = (new_global_position -  global_position) / delta
	global_position = new_global_position

	for arm in $Arms.get_children():
		arm.position = Vector2(arm_radius, 0).rotated(get_arm_angular_distance() * arm.index + rotation_cycle + fmod(2 * PI - (PI * (2.0 * pivot_index / arm_count + 1)), 2 * PI))

	if (difficulty == 0):
		curr_rotate_angle += arm_angle_speed


func enter_rotate_stop(_prev_state):
	#print("Stop: ", _prev_state)
	$RotateStop.start()

func enter_fall(_prev_state):
	velocity = linear_momentum
	for arm in $Arms.get_children():
		arm.get_node("WorldDetector").set_deferred("monitoring", false)
		arm.get_node("WorldDetector").set_deferred("monitorable", false)




func do_fall(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

	if (is_on_floor()):
		for a in $Arms.get_children():
			a.die()
		die()

func exit_fall(_next_state):
	velocity = Vector2.ZERO

### HELPERS ###

func get_arm_angular_distance() -> float:
	return (2 * PI) / float(arm_count)

func check_more_than_half_is_consecutively_mising() -> bool:
	var arms: Array = $Arms.get_children().filter(func (ele): return !ele.dead)
	arms = arms.map(func (ele): return ele.index)
	if arms.size() <= 1:
		return true
	arms.sort_custom(func (a, b): return a < b)
	# Check missing arms from the last to the first
	if (arm_count - arms[-1] - 1 + arms[0] >= arm_count / 2.0):
		return true
	# Check missing arm sequentially
	for i in range(1, arms.size()):
		if (arms[i] - arms[i - 1] - 1 >= arm_count / 2.0):
			return true
	return false

### SIGNALS ###

func on_arm_die(arm):
	if state == "fall": #dont bother when about to chase
		return

	# Having one last arm left or missing more than half of the arms, consecutively
	if arm.index == pivot_index or $Arms.get_child_count() == 1 or check_more_than_half_is_consecutively_mising():
		change_state.call_deferred("fall")


func on_arm_body_entered(_body, arm):
	var old_pivot_index = pivot_index
	pivot = arm
	pivot_pos = arm.global_position
	pivot_index = arm.index

	var arm_index_difference = fposmod(old_pivot_index - pivot_index, arm_count)
	rotation_cycle -= (2 * PI / arm_count) * arm_index_difference

	if (difficulty == 0 and state == "rotate" and curr_rotate_angle > tolerate_angle):
		change_state("rotate_stop")


func _on_RotateStop_timeout() -> void:
	change_state("rotate")
