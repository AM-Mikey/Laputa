extends Enemy

const ICON = preload("res://assets/Actor/Enemy/RollerIcon.png")
const LAND: = preload("res://src/Effect/LandParticle.tscn")

@export var start_dir = Vector2.LEFT
@onready var prev_global_position := global_position

var move_dir := Vector2.ZERO

var stuck := false
var stuck_grace_time := 0.2
var stuck_timer := 0.0

var current_vel := Vector2.ZERO
var on_floor: bool = false:
	set(val):
		just_landed = !on_floor and val
		on_floor = val
var on_slope: bool = false
var just_landed: bool = false
var floor_normal := Vector2.ZERO

const debug_name := "SpawnHole16"

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
	var floor_raycast_check = [$Floor, $LWall2, $RWall2, ]
	var floor_raycast: RayCast2D
	for fraycast in floor_raycast_check:
		if fraycast.is_colliding():
			floor_raycast = fraycast
			break
	if (on_floor and $LFloor.is_colliding() and $RFloor.is_colliding()):
		var left_floor_collide_pos = $LFloor.get_collision_point()
		var right_floor_collide_pos = $RFloor.get_collision_point()
		var floor_pos
		if (floor_raycast == $Floor):
			floor_pos = global_position + Vector2(0.0, -0.1)
		else:
			floor_pos = floor_raycast.get_collision_point()

		var left_floor_angle := angle_to_nearest_x_axis(left_floor_collide_pos.angle_to_point(floor_pos))
		var left_floor_angle_check := left_floor_angle > slope_detection_tolerance and left_floor_angle <= floor_max_angle
		var right_floor_angle := angle_to_nearest_x_axis(right_floor_collide_pos.angle_to_point(floor_pos))
		var right_floor_angle_check := right_floor_angle > slope_detection_tolerance and right_floor_angle <= floor_max_angle
		on_slope = left_floor_angle_check and right_floor_angle_check

		#if (name == debug_name):
			#print(rad_to_deg(left_floor_angle_check), " ", rad_to_deg(right_floor_angle_check))

		if (left_floor_angle_check and right_floor_angle_check):
			floor_normal = left_floor_collide_pos.direction_to(right_floor_collide_pos).orthogonal()
		elif left_floor_angle_check:
			floor_normal = left_floor_collide_pos.direction_to(floor_pos).orthogonal()
		elif right_floor_angle_check:
			floor_normal = floor_pos.direction_to(right_floor_collide_pos).orthogonal()
	elif (on_floor and ($LFloor.is_colliding() or $RFloor.is_colliding())):
		if !(($LFloor.is_colliding() and floor_raycast == $RWall2) or ($RFloor.is_colliding() and floor_raycast == $LWall2)):
			var offside_raycast: RayCast2D = $LFloor if $LFloor.is_colliding() else $RFloor
			var offside_collide_pos = offside_raycast.get_collision_point()
			var floor_pos
			if (floor_raycast == $Floor):
				floor_pos = global_position + Vector2(0.0, -0.1)
			else:
				floor_pos = floor_raycast.get_collision_point()
			#if (name == debug_name):
				#print(floor_pos, " -> ", offside_collide_pos, " = ",rad_to_deg(fmod(abs(offside_collide_pos.angle_to_point(floor_pos)), PI)))

			var angle_check = angle_to_nearest_x_axis(offside_collide_pos.angle_to_point(floor_pos))
			on_slope = angle_check > slope_detection_tolerance and angle_check <= floor_max_angle

			#if (name == debug_name):
				#print(rad_to_deg(angle_check))

			floor_normal = floor_pos.direction_to(offside_collide_pos).orthogonal()
			if (offside_raycast == $LFloor):
				floor_normal = -floor_normal
	else:
		on_slope = false
		floor_normal = Vector2.ZERO

	current_vel = calc_velocity(move_dir, true, false, false)

	var collision = move_and_collide(current_vel * delta)
	animate()

	if (collision and !on_floor and !on_slope): # Allow it to lodging into 1 tile-gap instead of move over it
		var c := move_and_collide(Vector2(0, current_vel.y) * delta)

		if c != null:
			var diff := c.get_position().x - global_position.x
			if absf(diff) < 0.1:
				pass
			elif diff < 0:
				move_and_collide(Vector2(0.15, 0.0))
			else:
				move_and_collide(Vector2(-0.15, 0.0))

	#if (name == debug_name):
		#print("A: ", current_vel, " Move dir: ", move_dir, ", Floor: ", on_floor, ", Slope: ", on_slope,", Stuck: ", stuck)
		#print("B: ", prev_global_position - global_position)

	if ($TurnTimer.time_left <= 0):
		var right_wall_contact = $RWall.is_colliding() or $RWall2.is_colliding()
		var left_wall_contact = $LWall.is_colliding() or $LWall2.is_colliding()
		var wall_contact = (move_dir.x > 0 and right_wall_contact) or (move_dir.x <= 0 and left_wall_contact)
		var check_flag = wall_contact and !stuck

		if on_slope:
			var free_opposite_slope: bool = (move_dir.x > 0 and !left_wall_contact) or (move_dir.x <= 0 and !right_wall_contact)
			check_flag = wall_contact and free_opposite_slope and !stuck

		if check_flag:
			move_dir.x *= -1.0
			am.play("enemy_jump", self)
			$TurnTimer.start()

	if (prev_global_position - global_position).length() <= 0.25:
		if (stuck_timer <= stuck_grace_time):
			stuck_timer += delta
		if (!stuck and stuck_timer > stuck_grace_time):
			stuck = true
	else:
		stuck = false
		stuck_timer = 0.0

	prev_global_position = global_position

var move_velocity: Vector2 = Vector2.ZERO
var gravity_velocity: Vector2 = Vector2.ZERO
func calc_velocity(move_dir, do_gravity = true, do_acceleration = false, do_friction = false) -> Vector2:
	var out := Vector2.ZERO
	var in_water_mult := Vector2.ONE if !is_in_water else Vector2(0.666, 0.666)

	move_velocity = speed * move_dir * in_water_mult

	if !on_floor or on_slope:
		var add_gravity: float = gravity * get_physics_process_delta_time()
		if on_slope:
			move_velocity = move_velocity.slide(floor_normal)
			gravity_velocity = gravity_velocity.slide(floor_normal)
			var max_x := speed.x * 1.0 / tan(floor_normal.angle() - (PI / 2.0))
			## Exchange excess gravity velocity into proper slide to avoid the Engine spazzing out with move_and_slide():
			if (abs(gravity_velocity.x) <= abs(max_x)):
				var excess_gravity := Vector2(0, add_gravity)
				var convert_vel := excess_gravity.slide(floor_normal)
				#if (name == debug_name):
					#print("A: ", excess_gravity, " slide ", floor_normal, " ", convert_vel)
				gravity_velocity += convert_vel
		else:
			if (abs(gravity_velocity.x) <= 0.01):
				gravity_velocity.x = 0.0
			else:
				gravity_velocity.x = move_toward(gravity_velocity.x, 0.0, 1.0)
			gravity_velocity.x = abs(gravity_velocity.x) * move_dir.x
			gravity_velocity.y += add_gravity
	else:
		if (just_landed and abs(gravity_velocity.y) >= 10.0):
			if (abs(gravity_velocity.y) > 100.0):
				am.play("pc_land")
				var effect = LAND.instantiate()
				effect.position = global_position
				world.get_node("Front").add_child(effect)
			gravity_velocity.y = -abs(gravity_velocity.y) * 0.2

		else:
			gravity_velocity.x = move_toward(gravity_velocity.x, 0.0, 1.0)
			gravity_velocity.x = abs(gravity_velocity.x) * move_dir.x
			gravity_velocity.y = 0.0

	#if (name == debug_name):
		#print(move_velocity, " ", gravity_velocity, " ", floor_normal)

	out = gravity_velocity + move_velocity
	return out

func animate():
	if (stuck):
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("Roll", -1.0, current_vel.length() / 80.0)
		match move_dir:
			Vector2.LEFT: $Sprite2D.flip_h = false
			Vector2.RIGHT: $Sprite2D.flip_h = true

# Return value in [0, PI / 2.0]
func angle_to_nearest_x_axis(angle: float) -> float:
	var proc_angle = fmod(abs(angle), PI)
	if (proc_angle > PI / 2.0):
		proc_angle = PI - proc_angle
	return proc_angle
