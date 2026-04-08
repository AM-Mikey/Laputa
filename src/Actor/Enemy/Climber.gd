extends Enemy

const ICON = preload("res://assets/Actor/Enemy/ClimberIcon.png")
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
		arm.arm_die.connect(on_arm_die)
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

func do_rotate(_delta):
	if debug:
		for a in $Arms.get_children():
			a.modulate = Color.WHITE
			pivot.modulate = Color.RED

	if climb_dir == "cw": rotation_cycle += arm_angle_speed
	elif climb_dir == "ccw": rotation_cycle -= arm_angle_speed
	global_position = pivot_pos + Vector2(cos(rotation_cycle), sin(rotation_cycle)) * arm_radius

	for arm in $Arms.get_children():
		arm.position = Vector2(arm_radius, 0).rotated(get_arm_angular_distance() * arm.index + rotation_cycle + fmod(2 * PI - (PI * (2.0 * pivot_index / arm_count + 1)), 2 * PI))

func enter_fall(_prev_state):
	$GroundDetector/CollisionShape2D.set_deferred("disabled", false)
	for arm in $Arms.get_children():
		arm.get_node("WorldDetector").set_deferred("monitoring", false)
		arm.get_node("WorldDetector").set_deferred("monitorable", false)

func do_fall(_delta):
	velocity = calc_velocity(Vector2(0,0), true)
	move_and_slide()

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
		change_state("fall")


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
		die()
