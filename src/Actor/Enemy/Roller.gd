extends Enemy

const ICON = preload("res://assets/Actor/Enemy/RollerIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Roller.png")

const BONK = preload("res://src/Effect/BonkParticle.tscn")
const LAND := preload("res://src/Effect/LandParticle.tscn")
const SPARK := preload("res://src/Effect/Spark.tscn")

@export var difficulty := 0
@export var diff_1_bounce_factor := 0.7
@export var start_dir = Vector2.LEFT

var move_dir := Vector2.ZERO

var prev_global_position := global_position

var stuck := false
var stuck_grace_time := 0.2
var stuck_timer := 0.0

var move_velocity := Vector2.ZERO
var gravity_velocity := Vector2.ZERO
var on_floor := false:
	set(val):
		just_landed = !on_floor && val
		on_floor = val
var on_slope := false
var just_landed := false
var floor_normal := Vector2.ZERO
var last_collision = null
const max_wall_upper_angle := PI / 3.0
var ceil_bounce_next_frame := false
const slope_detection_tolerance: float = PI / 90.0



func setup(): #Reminder: no function called can use await before emit
	hp = 3
	reward = 2
	damage_on_contact = 2
	speed = Vector2(60, 60)
	acceleration = 50
	gravity = 200
	gravity_velocity = velocity
	if velocity != Vector2.ZERO:
		move_dir = Vector2(-1.0 if signf(velocity.x) <= 0.0 else 1.0, 0.0)
	else:
		move_dir = start_dir

	if difficulty == 0:
		$Sprite2D.modulate = Color.WHITE
	elif difficulty == 1: #TODO: add sprites
		$Sprite2D.modulate = Color.DEEP_PINK

	prev_global_position = global_position
	set_up_direction(FLOOR_NORMAL)
	_animate()
	is_wind_affected = true
	w.emit_signal("finished_spawn_entities_step")


func _on_physics_process(delta):
	if disabled || dead: return
	on_floor = $Floor.is_colliding() || $LWall2.is_colliding() || $RWall2.is_colliding()
	var floor_raycast: RayCast2D
	for r in [$Floor, $LWall2, $RWall2]:
		if r.is_colliding():
			floor_raycast = r
			break

	if difficulty == 0:
		if on_floor && $LFloor.is_colliding() && $RFloor.is_colliding():
			var left_floor_collide_pos = $LFloor.get_collision_point()
			var right_floor_collide_pos = $RFloor.get_collision_point()
			var floor_pos
			if floor_raycast == $Floor:
				floor_pos = global_position + Vector2(0.0, -0.1)
			else:
				floor_pos = floor_raycast.get_collision_point()

			var left_floor_angle := _angle_to_nearest_x_axis(left_floor_collide_pos.angle_to_point(floor_pos))
			var is_left_floor_angle := left_floor_angle > slope_detection_tolerance && left_floor_angle <= floor_max_angle
			var right_floor_angle := _angle_to_nearest_x_axis(right_floor_collide_pos.angle_to_point(floor_pos))
			var is_right_floor_angle := right_floor_angle > slope_detection_tolerance && right_floor_angle <= floor_max_angle
			on_slope = is_left_floor_angle && is_right_floor_angle

			if is_left_floor_angle && is_right_floor_angle:
				floor_normal = left_floor_collide_pos.direction_to(right_floor_collide_pos).orthogonal()
			elif is_left_floor_angle:
				floor_normal = left_floor_collide_pos.direction_to(floor_pos).orthogonal()
			elif is_right_floor_angle:
				floor_normal = floor_pos.direction_to(right_floor_collide_pos).orthogonal()

		elif on_floor && ($LFloor.is_colliding() || $RFloor.is_colliding()):
			if !($LFloor.is_colliding() && floor_raycast == $RWall2) || ($RFloor.is_colliding() && floor_raycast == $LWall2):
				var offside_raycast: RayCast2D = $LFloor if $LFloor.is_colliding() else $RFloor
				var offside_collide_pos = offside_raycast.get_collision_point()
				var floor_pos
				if floor_raycast == $Floor:
					floor_pos = global_position + Vector2(0.0, -0.1)
				else:
					floor_pos = floor_raycast.get_collision_point()

				var angle_check = _angle_to_nearest_x_axis(offside_collide_pos.angle_to_point(floor_pos))
				on_slope = angle_check > slope_detection_tolerance && angle_check <= floor_max_angle

				floor_normal = floor_pos.direction_to(offside_collide_pos).orthogonal()
				if offside_raycast == $LFloor:
					floor_normal = -floor_normal
		else:
			on_slope = false
			floor_normal = Vector2.ZERO
	else:
		on_slope = false
		floor_normal = Vector2.ZERO

	velocity = _calc_velocity_rolling()
	last_collision = move_and_collide(velocity * delta)
	_animate()

	if last_collision != null && !on_floor && !on_slope: # Allow it to lodging into 1 tile-gap instead of move over it
		var c := move_and_collide(Vector2(0, velocity.y) * delta)

		if c != null:
			var diff := c.get_position().x - global_position.x
			if absf(diff) < 0.1:
				pass
			elif diff < 0:
				move_and_collide(Vector2(0.15, 0.0))
			else:
				move_and_collide(Vector2(-0.15, 0.0))

	if $TurnTimer.time_left <= 0:
		var center_point := global_position + Vector2(0, -8)
		var right_wall_top = last_collision != null && center_point.angle_to_point(last_collision.get_position()) <= 0.0 && center_point.angle_to_point(last_collision.get_position()) >= -max_wall_upper_angle
		var right_wall_contact = $RWall.is_colliding() || $RWall2.is_colliding() || right_wall_top
		var left_wall_top = last_collision != null && center_point.angle_to_point(last_collision.get_position()) <= -PI + max_wall_upper_angle
		var left_wall_contact = $LWall.is_colliding() || $LWall2.is_colliding() || left_wall_top
		var wall_contact = (move_dir.x > 0 && right_wall_contact) || (move_dir.x <= 0 && left_wall_contact)
		var normal_contact = wall_contact && !stuck

		if on_slope:
			var free_opposite_slope: bool = (move_dir.x > 0 && !left_wall_contact) || (move_dir.x <= 0 && !right_wall_contact)
			normal_contact = wall_contact && free_opposite_slope && !stuck

		if normal_contact:
			move_dir.x *= -1.0
			am.play("enemy_slam", self, null, 0.8, 0.1)
			var spark = SPARK.instantiate()
			spark.position = global_position
			w.front.add_child(spark)
			$TurnTimer.start()
			if difficulty == 1:
				gravity_velocity.x = -gravity_velocity.x

	_check_stuck(delta)
	prev_global_position = global_position


func _animate():
	if stuck:
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("Roll", -1.0, velocity.length() / 80.0)
		match move_dir:
			Vector2.LEFT: $Sprite2D.flip_h = false
			Vector2.RIGHT: $Sprite2D.flip_h = true



### HELPERS ###

func _check_stuck(delta):
	if (prev_global_position - global_position).length() <= 0.25:
		if stuck_timer <= stuck_grace_time:
			stuck_timer += delta
		if !stuck && stuck_timer > stuck_grace_time:
			stuck = true
	else:
		stuck = false
		stuck_timer = 0.0


func _create_effect(vfx_name):
	if last_collision != null:
		match vfx_name:
			"Land":
				var land = LAND.instantiate()
				land.global_position = last_collision.get_position()
				land.rotation = last_collision.get_normal().rotated(PI / 2.0).angle()
				w.front.add_child(land)
			"Bonk":
				var bonk = BONK.instantiate()
				bonk.normal = last_collision.get_normal()
				bonk.global_position = last_collision.get_position() + Vector2(0, 16)
				w.front.add_child(bonk)
			"Spark":
				var spark = SPARK.instantiate()
				spark.global_position = last_collision.get_position()
				w.front.add_child(spark)



### GETTERS ###

func _calc_velocity_rolling() -> Vector2:
	var in_water_mult := Vector2.ONE if !is_in_water else Vector2(0.666, 0.666)

	move_velocity = speed * move_dir * in_water_mult

	if ceil_bounce_next_frame:
		am.play("enemy_metal_thud", self, null, gravity_velocity.length() / 25.0)
		if gravity_velocity.length() > 100.0:
			_create_effect("Land")
		if gravity_velocity.length() > 250.0:
			_create_effect("Bonk")
		gravity_velocity = -gravity_velocity * diff_1_bounce_factor
		ceil_bounce_next_frame = false
	else:
		if !on_floor || on_slope:
			var add_gravity: float = gravity * get_physics_process_delta_time()
			if on_slope:
				move_velocity = move_velocity.slide(floor_normal)
				gravity_velocity = gravity_velocity.slide(floor_normal)
				var max_x := speed.x * 1.0 / tan(floor_normal.angle() - (PI / 2.0))
				## Exchange excess gravity velocity into proper slide to avoid the Engine spazzing out with move_and_slide():
				if abs(gravity_velocity.x) <= abs(max_x):
					var excess_gravity := Vector2(0, add_gravity)
					var convert_vel := excess_gravity.slide(floor_normal)
					gravity_velocity += convert_vel
			else:
				if abs(gravity_velocity.x) <= 0.01:
					gravity_velocity.x = 0.0
				else:
					gravity_velocity.x = move_toward(gravity_velocity.x, 0.0, 1.0)
				gravity_velocity.x = abs(gravity_velocity.x) * move_dir.x
				gravity_velocity.y += add_gravity
				var collision = move_and_collide((gravity_velocity + move_velocity) * get_physics_process_delta_time(), true)
				var ceil_angle = PI / 3.0
				if collision != null:
					var check_angle := (global_position + Vector2(0, -8.0)).angle_to_point(collision.get_position())
					if check_angle >= -PI / 2.0 - ceil_angle && check_angle <= -PI / 2.0 + ceil_angle:
						ceil_bounce_next_frame = true
		else:
			if just_landed:
				if difficulty == 0 && abs(gravity_velocity.y) >= 10.0:
					am.play("enemy_metal_thud", self, null, gravity_velocity.length() / 25.0)
					if last_collision != null:
						if gravity_velocity.length() > 100.0:
							_create_effect("Land")
						if gravity_velocity.length() > 250.0:
							_create_effect("Bonk")
					gravity_velocity.y = -abs(gravity_velocity.y) * 0.2
				elif difficulty == 1:
					if abs(gravity_velocity.y) >= 5.0:
						am.play("enemy_metal_thud", self, null, gravity_velocity.length() / 25.0)
						if last_collision != null:
							if gravity_velocity.length() > 100.0:
								_create_effect("Land")
							if gravity_velocity.length() > 250.0:
								_create_effect("Bonk")
						gravity_velocity = -gravity_velocity * diff_1_bounce_factor
					else:
						gravity_velocity = Vector2.ZERO
			else:
				gravity_velocity.x = move_toward(gravity_velocity.x, 0.0, 1.0)
				gravity_velocity.x = abs(gravity_velocity.x) * move_dir.x
				gravity_velocity.y = 0.0

	return gravity_velocity + move_velocity


func _angle_to_nearest_x_axis(angle: float) -> float: # Return value in [0, PI / 2.0]
	var proc_angle = fmod(abs(angle), PI)
	if proc_angle > PI / 2.0:
		proc_angle = PI - proc_angle
	return proc_angle
