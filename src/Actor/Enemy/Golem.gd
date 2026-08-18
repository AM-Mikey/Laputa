extends Enemy

const ICON = preload("res://assets/Actor/Enemy/GolemIcon.png")
#const WAYPOINT = preload("res://src/Editor/VisualUtility/WaypointGlobal.tscn")

const TX_0 = preload("res://assets/Actor/Enemy/Golem.png")

var move_dir = Vector2.LEFT
@export var difficulty := 0
var max_difficulty = 0
@export var charge_time := 15.0

var on_floor := false
var on_wall := false
var on_edge := false

var move_velocity := Vector2.ZERO
var gravity_velocity := Vector2.ZERO

func setup(): #Reminder: no function called can use await
	match difficulty:
		0:
			$Sprite2D.texture = TX_0
			hp = 6
			reward = 2
			damage_on_contact = 1
			speed = Vector2(50, 50)

	is_wind_affected = false
	move_dir = $VUVector.direction.snappedf(1.0)
	add_collision_exception_with($Standable)
	w.emit_signal("finished_spawn_entities_step")
	change_state("walk")

### STATES ###
func do_walk(_delta):
	if on_wall || \
	(on_floor && !$FloorDetectorL.is_colliding() && move_dir.x < 0) || \
	(on_floor && !$FloorDetectorR.is_colliding() && move_dir.x > 0):
		move_dir.x = -move_dir.x
		$Sprite2D.flip_h = sign(move_dir.x) == 1
	velocity = calc_velocity(move_dir)
	move_and_slide()


func calc_velocity(dir, do_gravity = true, do_acceleration = true, do_friction = true) -> Vector2:
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
