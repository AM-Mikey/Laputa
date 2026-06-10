extends Enemy

const ICON = preload("res://assets/Actor/Enemy/RollerIcon.png")

@export var start_dir = Vector2.LEFT

var move_dir

@onready var prev_global_position := global_position

enum StuckState {NONE, ATTEMPT_UNSTUCK, STUCK}
var stuck_state: StuckState = StuckState.NONE
var stuck_grace_time := 0.2
var attempt_unstuck_time := 0.15
var stuck_timer := 0.0

var current_vel := Vector2.ZERO
var on_floor: bool = false
var on_slope: bool = false
var floor_normal := Vector2.ZERO

const debug_name := "SpawnHole2"

func setup(): #Reminder: no function called can use await
	hp = 3
	reward = 2
	damage_on_contact = 2
	speed = Vector2(60, 60)
	acceleration = 50
	gravity = 200
	if (velocity != Vector2.ZERO):
		move_dir = Vector2(signf(velocity.x), 0.0)
	else:
		move_dir = start_dir
	set_up_direction(FLOOR_NORMAL)
	animate()
	w.emit_signal("finished_spawn_entities_step")

const slope_detection_tolerance: float = PI / 90.0
func _on_physics_process(delta):
	if disabled or dead: return
	on_floor = $Floor.is_colliding() or $LWall2.is_colliding() or $RWall2.is_colliding()
	if (on_floor and $LFloor.is_colliding() and $RFloor.is_colliding()):
		var left_floor_collide_pos = $LFloor.get_collision_point()
		var right_floor_collide_pos = $RFloor.get_collision_point()
		var floor_pos = global_position + Vector2(0.0, -0.2)

		var left_floor_angle_check := angle_to_nearest_x_axis(left_floor_collide_pos.angle_to_point(floor_pos)) > slope_detection_tolerance
		var right_floor_angle_check := angle_to_nearest_x_axis(right_floor_collide_pos.angle_to_point(floor_pos)) > slope_detection_tolerance
		on_slope = left_floor_angle_check and right_floor_angle_check

		if (left_floor_angle_check and right_floor_angle_check):
			floor_normal = left_floor_collide_pos.direction_to(right_floor_collide_pos).orthogonal()
		elif left_floor_angle_check:
			floor_normal = left_floor_collide_pos.direction_to(floor_pos).orthogonal()
		elif right_floor_angle_check:
			floor_normal = floor_pos.direction_to(right_floor_collide_pos).orthogonal()
	elif (on_floor and ($LFloor.is_colliding() or $RFloor.is_colliding())):
		var offside_raycast: RayCast2D = $LFloor if $LFloor.is_colliding() else $RFloor
		var offside_collide_pos = offside_raycast.get_collision_point()
		var floor_pos = global_position + Vector2(0.0, -0.2)
		#if (name == debug_name):
			#print(floor_pos, " -> ", offside_collide_pos, " = ",rad_to_deg(fmod(abs(offside_collide_pos.angle_to_point(floor_pos)), PI)))
		on_slope = angle_to_nearest_x_axis(offside_collide_pos.angle_to_point(floor_pos)) > slope_detection_tolerance

		floor_normal = floor_pos.direction_to(offside_collide_pos).orthogonal()
		if (offside_raycast == $LFloor):
			floor_normal = -floor_normal
	else:
		on_slope = false
		floor_normal = Vector2.ZERO

	current_vel = calc_velocity(move_dir, true, false, false)

	velocity = current_vel
	move_and_slide()
	animate()

	#if (name == debug_name):
		#print(current_vel, " -> ", velocity, " Move dir: ", move_dir, ", Floor: ", on_floor, ", Slope: ", on_slope,", Stuck: ", stuck_state == StuckState.STUCK)

	if ($TurnTimer.time_left <= 0):
		var right_wall_contact = $RWall.is_colliding() or $RWall2.is_colliding()
		var left_wall_contact = $LWall.is_colliding() or $LWall2.is_colliding()
		var wall_contact = (move_dir.x > 0 and right_wall_contact) or (move_dir.x <= 0 and left_wall_contact)
		var free_opposite_slope = true
		if on_slope:
			free_opposite_slope = (move_dir.x > 0 and !left_wall_contact) or (move_dir.x <= 0 and !right_wall_contact)

		if wall_contact and free_opposite_slope and stuck_state != StuckState.STUCK:
			move_dir.x *= -1.0
			am.play("enemy_jump", self)
			$TurnTimer.start()

	var try_unstuck_flag: bool = false
	if (prev_global_position - global_position).length() <= 0.25:
		if (stuck_timer <= stuck_grace_time):
			stuck_timer += delta
		if (stuck_state == StuckState.NONE and stuck_timer > attempt_unstuck_time):
			stuck_state = StuckState.ATTEMPT_UNSTUCK
			global_position.y -= 0.05
			try_unstuck_flag = true
		elif (stuck_state == StuckState.ATTEMPT_UNSTUCK and stuck_timer > stuck_grace_time):
			stuck_state = StuckState.STUCK
	else:
		stuck_state = StuckState.NONE
		stuck_timer = 0.0

	if (try_unstuck_flag):
		prev_global_position = global_position + Vector2(0.0, 0.05)
	else:
		prev_global_position = global_position


var move_velocity: Vector2 = Vector2.ZERO
var gravity_convert_vel: Vector2 = Vector2.ZERO
var gravity_velocity: Vector2 = Vector2.ZERO
func calc_velocity(move_dir, do_gravity = true, do_acceleration = false, do_friction = false) -> Vector2:
	var out := Vector2.ZERO
	var in_water_mult := Vector2.ONE if !is_in_water else Vector2(0.666, 0.666)

	move_velocity = speed * move_dir * in_water_mult

	if !on_floor or on_slope:
		gravity_velocity.y += gravity * get_physics_process_delta_time()
		if on_slope:
			const max_grav: float = 50.0
			const max_x: float = 20.0
			## Exchange excess gravity velocity into proper slide to avoid the Engine spazzing out with move_and_slide():
			if (abs(current_vel.x) <= max_x):
				if (gravity_velocity.y > max_grav):
					var excess_gravity := Vector2(0, gravity_velocity.y - max_grav)
					var convert_vel := excess_gravity.slide(floor_normal)
					#if (name == debug_name):
						#print("A: ", current_vel, " slide ", floor_normal, " ", convert_vel)
					gravity_convert_vel += convert_vel
					gravity_velocity.y = min(gravity_velocity.y, max_grav)
			else:
				gravity_velocity.y = min(gravity_velocity.y, max_grav)
		else:
			gravity_convert_vel = lerp(gravity_convert_vel, Vector2.ZERO, 0.2);
	else:
		gravity_velocity.y = 0.0
		gravity_convert_vel = Vector2.ZERO

	#if (name == debug_name):
		#print(move_velocity, " ", gravity_velocity, " ", gravity_convert_vel)

	out = gravity_velocity + move_velocity + gravity_convert_vel
	return out

func animate():
	if (stuck_state == StuckState.STUCK):
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("Roll", -1.0, velocity.length() / 80.0)
		match move_dir:
			Vector2.LEFT: $Sprite2D.flip_h = false
			Vector2.RIGHT: $Sprite2D.flip_h = true

# Return value in [0, PI / 2.0]
func angle_to_nearest_x_axis(angle: float) -> float:
	var proc_angle = fmod(abs(angle), PI)
	if (proc_angle > PI / 2.0):
		proc_angle = PI - proc_angle
	return proc_angle
