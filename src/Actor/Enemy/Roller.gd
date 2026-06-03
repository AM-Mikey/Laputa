extends Enemy

const ICON = preload("res://assets/Actor/Enemy/RollerIcon.png")

@export var start_dir = Vector2.LEFT

var move_dir

@onready var prev_global_position := global_position
var stuck := false
var stuck_grace_timer := 0.2
var stuck_timer := 0.0

var current_vel := Vector2.ZERO
var on_floor: bool = false
var on_slope: bool = false

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


func _on_physics_process(delta):
	if disabled or dead: return
	on_floor = $Floor.is_colliding()
	on_slope = (move_dir.x > 0 and !$LFloor.is_colliding() and $RFloor.is_colliding()) \
				or (move_dir.x <= 0 and !$RFloor.is_colliding() and $LFloor.is_colliding())

	current_vel = calc_velocity(move_dir, true, false, false)

	velocity = current_vel
	move_and_slide()
	animate()
	if (name == "SpawnHole16"):
		print(current_vel, " -> ", velocity, ", Floor: ", on_floor, ", Slope: ", on_slope)

	if (prev_global_position - global_position).length() <= 0.1:
		if (stuck_timer <= stuck_grace_timer):
			stuck_timer += delta
		else:
			stuck = true
	else:
		stuck = false
		stuck_timer = 0.0

	if ($TurnTimer.time_left <= 0):
		var wall_contact = (move_dir.x > 0 and $RWall.is_colliding() or $RWall2.is_colliding()) \
							or (move_dir.x <= 0 and $LWall.is_colliding() or $LWall2.is_colliding())
		var free_opposite_slope = true
		if (on_floor and on_slope):
			free_opposite_slope = (move_dir.x > 0 and !$LFloor.is_colliding()) or \
								(move_dir.x <= 0 and !$RFloor.is_colliding())
		#if (name == "SpawnHole19"):
			#print(velocity, " Wall: ", wall_contact, ", Floor: ", on_floor, ", Slope: ", on_slope)

		if wall_contact and free_opposite_slope and !stuck:
			move_dir *= -1
			am.play("enemy_jump", self)
			$TurnTimer.start()

	prev_global_position = global_position

func calc_velocity(move_dir, do_gravity = true, do_acceleration = false, do_friction = false) -> Vector2:
	var out: = current_vel
	var fractional_speed = speed
	if is_in_water:
		fractional_speed = speed * Vector2(0.666, 0.666)

	#X
	if do_acceleration:
		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, fractional_speed.x)
			out.x *= move_dir.x
		elif do_friction:
			if on_floor:
				out.x = lerp(out.x, 0.0, ground_cof)
			else:
				out.x = lerp(out.x, 0.0, air_cof)
	else: #no acceleration
		if (on_floor and on_slope):
			fractional_speed.x = min(fractional_speed.x, 10.0)
		out.x = fractional_speed.x * move_dir.x

	#Y
	if do_gravity:
		if !on_floor or (on_floor and on_slope):
			out.y += gravity * get_physics_process_delta_time()
		else:
			out.y = 0.0
		if move_dir.y < 0:
			out.y = fractional_speed.y * move_dir.y

	return out

func animate():
	var displacement = (prev_global_position - global_position) / get_physics_process_delta_time()
	$AnimationPlayer.play("Roll", -1.0, displacement.length() / 80.0)
	if !stuck:
		match move_dir:
			Vector2.LEFT: $Sprite2D.flip_h = false
			Vector2.RIGHT: $Sprite2D.flip_h = true
