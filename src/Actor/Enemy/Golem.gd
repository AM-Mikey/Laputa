extends Enemy

const ICON = preload("res://assets/Actor/Enemy/GolemIcon.png")
#const WAYPOINT = preload("res://src/Editor/VisualUtility/WaypointGlobal.tscn")

const TX_0 = preload("res://assets/Actor/Enemy/Golem.png")

var move_dir = Vector2.LEFT
@export var difficulty := 0
var max_difficulty = 0
#@export var charge_time := 15.0
@export var wallslam_time := 1.2
var walk_speed = Vector2(40, 40)
var charge_speed = Vector2(100, 100)
var normal_damage = 2
var charge_damage = 6
@export var charge_impulse_curve : Curve
#var charge_shake_strength = 0.5
#var slam_shake_strength = 30.0

var on_floor := false
var on_wall := false
var on_edge := false

var move_velocity := Vector2.ZERO
var gravity_velocity := Vector2.ZERO

#charge when in front of or shot at enough times
#charge kills enemies with 999 damage when ran into
#charge does massive damage to juniper and flings ala shield
#charge hitting wall forces golem to get stuck and stay in place for a while (for good platforming)
#charge can make golem fall off ledges
#golem is invulerable to spikes
#golem can be shot at while on it, for cool riding fast part

#add screenshake to charge
#charge wallslam causes damage? and shakes screen and forces golem to recoil?


func setup(): #Reminder: no function called can use await
	match difficulty:
		0:
			$Sprite2D.texture = TX_0
			hp = 20
			reward = 5
			damage_on_contact = normal_damage
			speed = walk_speed

	is_wind_affected = false
	move_dir = $VUVector.direction.snappedf(1.0)
	add_collision_exception_with($Standable)
	w.emit_signal("finished_spawn_entities_step")
	change_state("walk")

### STATES ###
func enter_walk(_last_state):
	speed = walk_speed
	$AnimationPlayer.play("Walk")

func do_walk(_delta):
	if on_wall || \
	(on_floor && !$FloorDetectorL.is_colliding() && move_dir.x < 0) || \
	(on_floor && !$FloorDetectorR.is_colliding() && move_dir.x > 0):
		move_dir.x = -move_dir.x
		$Sprite2D.flip_h = sign(move_dir.x) == 1
	velocity = calc_velocity(move_dir)
	move_and_slide()


func enter_charge(_last_state):
	$AnimationPlayer.play("Charge")
	speed = charge_speed
	damage_on_contact = charge_damage

func exit_charge(_next_state):
	damage_on_contact = normal_damage

func do_charge(_delta):
	if on_wall:
		change_state("wallslam")
	velocity = calc_velocity(move_dir)
	move_and_slide()


func enter_wallslam(_last_state):
	$AnimationPlayer.play("WallSlam")
	speed = Vector2(0, 0)
	await get_tree().create_timer(wallslam_time, false, true).timeout
	move_dir.x = -move_dir.x
	$Sprite2D.flip_h = sign(move_dir.x) == 1
	change_state("walk")

#func do_wallslam(_delta):
	#pass



func _on_hit(_damage, _blood_direction):
	if state != "charge":
		change_state("charge")

func charge_shake():
	am.play("enemy_stomp", self, null, 0.8, 0.1)
	if f.pc():
		var player_distance = f.pc().global_position.distance_to(global_position)
		var max_distance := 512
		var max_shake_pixels := 4.0
		var shake_pixels = remap(player_distance, 0, max_distance, max_shake_pixels, 0.0)
		shake_pixels = clampf(shake_pixels, 0.0, max_shake_pixels)
		#f.pc().get_node("PlayerCamera").shake(shake_pixels, 0.2, 4.0)
		f.pc().get_node("PlayerCamera").impulse(Vector2.DOWN, shake_pixels, 0.2, charge_impulse_curve)

func slam_shake():
	am.play("enemy_slam", self)
	if f.pc():
		var player_distance = f.pc().global_position.distance_to(global_position)
		var max_distance := 512
		var max_shake_pixels := 16.0
		var shake_pixels = remap(player_distance, 0, max_distance, max_shake_pixels, 0.0)
		shake_pixels = clampf(shake_pixels, 0.0, max_shake_pixels)
		f.pc().get_node("PlayerCamera").shake(shake_pixels, 0.6, 16.0)

func calc_velocity(dir, _do_gravity = true, _do_acceleration = true, _do_friction = true) -> Vector2:
	var out: = Vector2.ZERO
	var fractional_speed = speed
	var delta := get_physics_process_delta_time()
	if is_in_water:
		fractional_speed = speed * Vector2(0.666, 0.666)

	var floor_collision: KinematicCollision2D = move_and_collide(Vector2.DOWN, true)
	var wall_collision: KinematicCollision2D = move_and_collide(move_dir.sign(), true)

	if floor_collision:
		var floor_normal_angle = floor_collision.get_normal().angle()
		on_floor = floor_normal_angle < -PI / 2.0 + floor_max_angle && floor_normal_angle > -PI / 2.0 - floor_max_angle
	else:
		on_floor = false

	if wall_collision:
		var wall_normal_angle = wall_collision.get_normal().angle()
		on_wall = abs(wall_normal_angle) >= PI / 2.0 + floor_max_angle || abs(wall_normal_angle) <= PI / 2.0 - floor_max_angle
	else:
		on_wall = false

	if on_wall:
		move_velocity = Vector2.ZERO
	else:
		move_velocity = dir * fractional_speed

	var gravity_amount := gravity * delta

	if !on_floor:
		if on_wall:
			var wall_normal = wall_collision.get_normal()
			gravity_velocity = (gravity_velocity + Vector2(0, gravity_amount)).slide(wall_normal)
		else:
			gravity_velocity.y += gravity_amount
	else:
		var floor_normal = floor_collision.get_normal()
		var floor_normal_angle = floor_normal.angle()
		if (floor_normal_angle < -PI / 2.0 + floor_max_angle && floor_normal_angle > deg_to_rad(-80)) || \
			(floor_normal_angle > -PI / 2.0 - floor_max_angle && floor_normal_angle < deg_to_rad(-100)):
			move_velocity = move_velocity.slide(floor_normal)

	out = move_velocity + gravity_velocity
	return out
