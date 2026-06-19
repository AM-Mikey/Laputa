extends Enemy

const ICON = preload("res://assets/Actor/Enemy/BillyIcon.png")
const SEED = preload("res://src/Bullet/Enemy/Seed.tscn")
const WAYPOINT = preload("res://src/Editor/VisualUtility/WaypointGlobal.tscn")

const TX_0 = preload("res://assets/Actor/Enemy/Billy0.png")
const TX_1 = preload("res://assets/Actor/Enemy/Billy1.png")

@export var move_dir = Vector2.LEFT
@export var look_dir = Vector2.LEFT
@export var difficulty := 0
var max_difficulty := 1
@export var idle_max_time = 5.0
@export var walk_max_time = 10.0
@export var defend_time = 0.4


@export var cooldown_time = 1
@export var bullet_speed: int = 200
@export var bullet_damage: int = 2


@export var lock_distance = 128
@export var lock_tolerance = 16

const JUMP_VELOCITY: float = -1100.0

var target: Node
var locked_on = false
var shooting = false

var waypoint

@onready var ap = $AnimationPlayer



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

	w.emit_signal("finished_spawn_entities_step")
	change_state("walk")

### STATES ###

func enter_walk(_last_state):
	ap.play("Walk")

	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, walk_max_time))
	await $StateTimer.timeout
	change_state("idle")

func do_walk(_delta):
	if is_on_wall() || \
		(!$FloorDetectorL.is_colliding() && move_dir.x < 0) || \
		(!$FloorDetectorR.is_colliding() && move_dir.x > 0):
		move_dir.x = -move_dir.x
		look_dir.x = move_dir.x
	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
		velocity = calc_velocity(move_dir)
		move_and_slide()
	update_animation()

func enter_idle(_last_state):
	rng.randomize()
	ap.play("Idle")
	update_animation()
	$StateTimer.start(rng.randf_range(1.0, idle_max_time))
	await $StateTimer.timeout
	change_state("walk")

func do_idle(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

func do_aggro(_delta):
	if pc: #TODO: global enemy shutdown fix
		var target_dir = Vector2(sign(position.x - pc.position.x), 0)
		look_dir = target_dir * -1
		set_waypoint(target_dir)
	#this isnt the best way to do this, but returns a good result.
	#right now this cuts off move_dir when it's more than a block away (to -1 or 1)
	#the small adjustment when less than that is why we don't just use sign()
	var on_edge := false
	var displace_to_waypoint = waypoint.position.x - position.x
	var x_dir: float = clamp(displace_to_waypoint / 16.0, -1.0, 1.0)
	move_dir = Vector2(lerp(move_dir.x, x_dir, 0.2), 0)

	if	difficulty == 0 && is_on_floor() && \
		((!$FloorDetectorL.is_colliding() && move_dir.x < 0) || \
		(!$FloorDetectorR.is_colliding() && move_dir.x > 0)):
		move_dir.x = 0.0
		on_edge = true

	if on_edge:
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
	move_and_slide()

	update_animation()

func exit_aggro(_next_state):
	move_dir.x = 1.0 if signf(move_dir.x) >= 0 else -1.0

var is_jumping: bool = false
var jump_acceleration: float = 0.0
func calc_velocity(move_dir, do_gravity = true, do_acceleration = true, do_friction = true) -> Vector2:
	var default_value = super.calc_velocity(move_dir, do_gravity, do_acceleration, do_friction) #TODO: probably remove the super here
	if (difficulty == 1):
		if !(is_jumping):
			if !(is_on_floor()):
				return default_value
			var moving_right: bool = move_dir.x > 0
			var wall_is_slope: bool = false
			var wall_in_walking_direction: bool = false

			var collision: KinematicCollision2D = move_and_collide(8 * move_dir.sign(), true)
			if (collision):
				wall_is_slope = collision.get_angle() <= deg_to_rad(80)
				wall_in_walking_direction = true

			var check_raycast: bool = !$JumpDetectorR.is_colliding() and !$JumpDetectorRWall.is_colliding() if moving_right \
										else !$JumpDetectorL.is_colliding() and !$JumpDetectorLWall.is_colliding()
			if (is_on_wall() and wall_in_walking_direction and !wall_is_slope and check_raycast):
				jump_acceleration = JUMP_VELOCITY
				is_jumping = true
				$JumpAccelTimer.start()
				default_value.y = jump_acceleration * get_physics_process_delta_time()
		else:
			default_value.y += jump_acceleration * get_physics_process_delta_time()
			if ($JumpAccelTimer.time_left <= 0.0 and is_on_floor()):
				is_jumping = false
	return default_value

### HELPERS ###

func fire():
	var bullet = SEED.instantiate()

	bullet.damage = bullet_damage
	bullet.speed = bullet_speed
	bullet.position = $BulletOrigin.global_position
	bullet.origin = $BulletOrigin.global_position
	bullet.direction = Vector2(look_dir.x /2 , -1) #Adjust this for angle

	world.get_node("Middle").add_child(bullet)
	am.play("enemy_shoot", self)

func set_waypoint(target_dir: Vector2):
	if waypoint: waypoint.queue_free()
	waypoint = WAYPOINT.instantiate()
	waypoint.position = Vector2(pc.position.x + (lock_distance * target_dir.x), pc.position.y) #left or right of pc
	waypoint.owner_id = id
	waypoint.index = -1
	world.current_level.add_child(waypoint)

func update_animation():
	match look_dir.x:
		-1.0: $Sprite2D.flip_h = false
		1.0: $Sprite2D.flip_h = true

### SIGNALS ###

func _on_PlayerDetector_body_entered(_body):
	$StateTimer.stop()
	change_state("aggro")

func _on_PlayerDetector_body_exited(_body):
	if (state == "aggro"):
		change_state("idle")


func _on_JumpAccelTimer_timeout() -> void:
	jump_acceleration = 0

func _exit_tree() -> void:
	if waypoint:
		waypoint.queue_free()
