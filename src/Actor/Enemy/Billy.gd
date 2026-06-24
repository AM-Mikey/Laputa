extends Enemy

const ICON = preload("res://assets/Actor/Enemy/BillyIcon.png")
const SEED = preload("res://src/Bullet/Enemy/Seed.tscn")
const WAYPOINT = preload("res://src/Editor/VisualUtility/WaypointGlobal.tscn")

const TX_0 = preload("res://assets/Actor/Enemy/Billy0.png")
const TX_1 = preload("res://assets/Actor/Enemy/Billy1.png")

@export var move_dir = Vector2.LEFT
@export var difficulty := 0
@export var idle_max_time := 5.0
@export var walk_max_time := 10.0
@export var deaggro_delay := 3.0

@export var bullet_speed := 200
@export var bullet_damage :int = 2

@export var lock_distance := 128
@export var lock_tolerance := 16

const JUMP_VELOCITY := -1000.0
var look_dir := Vector2.LEFT

var target: Node
var locked_on := false
var shooting := false

var waypoint
var last_collision: KinematicCollision2D
var on_floor := false
var on_wall := false

var stuck_shooting := false

@onready var ap = $AnimationPlayer

var debug_name = "Billy39"

func setup(): #Reminder: no function called can use await
	match difficulty:
		0:
			$Sprite2D.texture = TX_0
			$JumpDetectorL.enabled = false
			$JumpDetectorR.enabled = false
			hp = 6
			reward = 2
			damage_on_contact = 1
			speed = Vector2(50, 50)
		1:
			$Sprite2D.texture = TX_1
			$JumpDetectorL.enabled = true
			$JumpDetectorR.enabled = true
			hp = 6
			reward = 3
			damage_on_contact = 2
			speed = Vector2(70, 70)

	$DeaggroTimer.wait_time = deaggro_delay
	waypoint = WAYPOINT.instantiate()
	waypoint.owner_id = id
	waypoint.index = -1
	w.current_level.get_node("Waypoints").add_child(waypoint)

	w.emit_signal("finished_spawn_entities_step")
	change_state("walk")

### STATES ###
func enter_walk(_last_state):
	ap.play("Walk")

	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, walk_max_time))
	await $StateTimer.timeout
	change_state("idle")

func do_walk(delta):
	if on_wall || \
		(!$FloorDetectorL.is_colliding() && move_dir.x < 0) || \
		(!$FloorDetectorR.is_colliding() && move_dir.x > 0):
		move_dir.x = -move_dir.x
		look_dir.x = move_dir.x
	velocity = calc_velocity(move_dir)
	last_collision = move_and_collide(velocity * delta)
	update_animation()

func enter_idle(_last_state):
	rng.randomize()
	ap.play("Idle")
	update_animation()

	if ($StateTimer.is_inside_tree()):
		$StateTimer.start(rng.randf_range(1.0, idle_max_time))
		await $StateTimer.timeout
		change_state("walk")

func do_idle(delta):
	velocity = calc_velocity(Vector2.ZERO)
	last_collision = move_and_collide(velocity * delta)

func do_aggro(delta):
	if pc: #TODO: global enemy shutdown fix
		var target_dir = Vector2(sign(position.x - pc.position.x), 0)
		look_dir = target_dir * -1
		waypoint.position = Vector2(pc.position.x + (lock_distance * target_dir.x), pc.position.y) #left or right of pc

	#this isnt the best way to do this, but returns a good result.
	#right now this cuts off move_dir when it's more than a block away (to -1 or 1)
	#the small adjustment when less than that is why we don't just use sign()
	var on_edge := false
	var displace_to_waypoint = waypoint.position.x - position.x
	var x_dir: float = clamp(displace_to_waypoint / 16.0, -1.0, 1.0)
	move_dir = Vector2(lerp(move_dir.x, x_dir, 0.2), 0)

	if	difficulty == 0 && on_floor && \
		((!$FloorDetectorL.is_colliding() && move_dir.x < 0) || \
		(!$FloorDetectorR.is_colliding() && move_dir.x > 0)):
		move_dir.x = 0.0
		on_edge = true

	if on_wall:
		ap.play("StandShoot")
		stuck_shooting = true
	else:
		stuck_shooting = false
		if on_edge:
			if abs(displace_to_waypoint) < lock_tolerance:
				ap.play("StandShoot")
			else:
				ap.play("Idle")
		else:
			if abs(displace_to_waypoint) < lock_tolerance:
				if abs(move_dir.x) < 0.1:
					ap.play("StandShoot")
				else:
					ap.play("WalkShoot")
			else:
				ap.play("Walk")


	velocity = calc_velocity(move_dir)
	last_collision = move_and_collide(velocity * delta)

	var floor_collision := move_and_collide(Vector2.DOWN, true)
	if floor_collision:
		var slide_normal_angle = floor_collision.get_normal().angle()
		if slide_normal_angle < 0.0 && (slide_normal_angle >= deg_to_rad(-80) || slide_normal_angle <= deg_to_rad(-100)):
			$Sprite2D.offset.y = 1
		else:
			$Sprite2D.offset.y = 0
	else:
		$Sprite2D.offset.y = 0

	update_animation()

func exit_aggro(_next_state):
	move_dir.x = 1.0 if signf(move_dir.x) >= 0 else -1.0
	stuck_shooting = false

var is_jumping := false
var jump_acceleration := 0.0
var move_velocity := Vector2.ZERO
var gravity_velocity := Vector2.ZERO
func calc_velocity(move_dir, do_gravity = true, do_acceleration = true, do_friction = true) -> Vector2:
	var out: = Vector2.ZERO
	var fractional_speed = speed
	var delta := get_physics_process_delta_time()
	if is_in_water:
		fractional_speed = speed * Vector2(0.666, 0.666)

	on_wall = false
	on_floor = false
	var floor_collision: KinematicCollision2D = move_and_collide(Vector2.DOWN, true)
	var wall_collision: KinematicCollision2D = move_and_collide(move_dir.sign(), true)

	if (floor_collision):
		var floor_normal_angle = floor_collision.get_normal().angle()
		on_floor = floor_normal_angle < -PI / 2.0 + floor_max_angle && floor_normal_angle > -PI / 2.0 - floor_max_angle

	if (wall_collision):
		var wall_normal_angle = wall_collision.get_normal().angle()
		on_wall = abs(wall_normal_angle) >= PI / 2.0 + floor_max_angle || abs(wall_normal_angle) <= PI / 2.0 - floor_max_angle

	move_velocity = move_dir * fractional_speed
	var gravity_amount := gravity * delta

	if !on_floor:
		if (wall_collision):
			var wall_normal = wall_collision.get_normal()
			var wall_normal_angle = wall_normal.angle()
			if (abs(wall_normal_angle) > PI - floor_max_angle || abs(wall_normal_angle) < floor_max_angle):
				move_velocity = move_velocity.slide(wall_normal)
				gravity_velocity = (gravity_velocity + Vector2(0, gravity_amount)).slide(wall_normal)
		else:
			gravity_velocity.y += gravity_amount
	else:
		var floor_normal = floor_collision.get_normal()
		var floor_normal_angle = floor_normal.angle()
		if (floor_normal_angle < -PI / 2.0 + floor_max_angle && floor_normal_angle > deg_to_rad(-80)) || \
			(floor_normal_angle > -PI / 2.0 - floor_max_angle && floor_normal_angle < deg_to_rad(-100)):
			move_velocity = move_velocity.slide(floor_normal)
		if !(difficulty == 1 && is_jumping):
			gravity_velocity = Vector2(0, gravity_amount)

	if difficulty == 1:
		if !is_jumping and state == "aggro":
			if !on_floor:
				return move_velocity + gravity_velocity
			var moving_right: bool = move_dir.x > 0
			var wall_is_slope: bool = false
			var wall_in_walking_direction: bool = false

			if (wall_collision):
				wall_is_slope = wall_collision.get_angle() <= floor_max_angle
				wall_in_walking_direction = true

			var check_raycast: bool = !$JumpDetectorR.is_colliding() and !$JumpDetectorRWall.is_colliding() if moving_right \
										else !$JumpDetectorL.is_colliding() and !$JumpDetectorLWall.is_colliding()
			if (wall_in_walking_direction and !wall_is_slope and check_raycast):
				jump_acceleration = JUMP_VELOCITY
				is_jumping = true
				$JumpAccelTimer.start()
				gravity_velocity.x = 0.0
				gravity_velocity.y = jump_acceleration * delta
		else:
			gravity_velocity.y += jump_acceleration * delta
			if $JumpAccelTimer.time_left <= 0.0 and on_floor:
				is_jumping = false

	out = move_velocity + gravity_velocity
	#if (name == debug_name):
		#print(state, " ", move_dir, " ", out, " ", move_velocity, " ", gravity_velocity)
	return out

### HELPERS ###

func fire():
	var bullet = SEED.instantiate()

	bullet.damage = bullet_damage
	bullet.position = $BulletOrigin.global_position
	bullet.origin = $BulletOrigin.global_position

	if !stuck_shooting: #Normal shooting
		bullet.speed = bullet_speed
		bullet.direction = Vector2(look_dir.x / 2 , -1) #Adjust this for angle
	else:
		# Even when shooting at close range, the arc will always peak at the same height as normal shooting
		var normal_start_bullet_vel_y = bullet_speed * sin(Vector2(look_dir.x / 2.0, -1).angle())
		var normal_time_peak_reached = abs(normal_start_bullet_vel_y / bullet.gravity)
		var peak_y = 0.5 * bullet.gravity * pow(normal_time_peak_reached, 2) + normal_start_bullet_vel_y * normal_time_peak_reached
		var normal_time_travel = sqrt(abs((peak_y + $BulletOrigin.position.y) / 0.5 / bullet.gravity)) + normal_time_peak_reached
		var target_distance_x = (waypoint.global_position.x + lock_distance * look_dir.x) - $BulletOrigin.global_position.x

		var b_speed_x = target_distance_x / normal_time_travel
		var b_speed_y = (peak_y - 0.5 * bullet.gravity * pow(normal_time_peak_reached, 2)) / normal_time_peak_reached
		bullet.speed = Vector2(b_speed_x, b_speed_y).length()
		bullet.direction = Vector2(b_speed_x, b_speed_y).normalized()

		#if name == debug_name:
			#print("B ", bullet.speed, " ", bullet.direction)
			#print(peak_y, " ", abs(0.5 * bullet.gravity * pow(normal_time_peak_reached, 2)))

	world.get_node("Middle").add_child(bullet)
	am.play("enemy_shoot", self)

func update_animation():
	match look_dir.x:
		-1.0: $Sprite2D.flip_h = false
		1.0: $Sprite2D.flip_h = true

### SIGNALS ###

func _on_PlayerDetector_body_entered(_body):
	$StateTimer.stop()
	$DeaggroTimer.stop()
	change_state("aggro")

func _on_PlayerDetector_body_exited(_body):
	if (state == "aggro" && $DeaggroTimer.is_inside_tree()):
		$DeaggroTimer.start()

func _on_DeaggroTimer_timeout() -> void:
	if (state == "aggro"):
		change_state("idle")

func _on_JumpAccelTimer_timeout() -> void:
	jump_acceleration = 0

func _exit_tree() -> void:
	if waypoint:
		waypoint.queue_free()
