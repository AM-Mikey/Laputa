extends Enemy

var move_dir: Vector2
var idle = false
var idle_time: float
var active_time: float

func _ready():
	hp = 1
	damage_on_contact = 0
	speed = Vector2(100, 100)

	level = 0

	rng.randomize()
	move_dir = Vector2(sign(rng.randf_range(-1, 1)), 0)
	idle_time = rng.randf_range(0.5, 2)
	active_time = rng.randf_range(2, 4)
	
	$Timer.wait_time = active_time
	
func _physics_process(delta):
	if not dead:
		_velocity = calculate_move_velocity(_velocity, move_dir, speed)
		_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
		
		animate(move_dir)
		
		if is_on_wall():
			if idle == false:
				move_dir *= -1

func wait(move_dir):
	idle = true
	var old_speed = speed
	speed = Vector2.ZERO
	$Timer.start(idle_time)
	
	if move_dir.x != 0:
		move_dir.x *= -1
		if move_dir.x == -1:
			$AnimationPlayer.play("IdleLeft")
		if move_dir.x == 1:
			$AnimationPlayer.play("IdleRight")

	yield($Timer, "timeout")
	rng.randomize()
	move_dir = Vector2(sign(rng.randf_range(-1, 1)), 0)
	idle = false
	speed = old_speed
	$Timer.start(active_time)

func calculate_move_velocity(linear_velocity: Vector2, move_direction: Vector2, speed: Vector2) -> Vector2:
	var out: = linear_velocity
	var friction = false
	
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y

	if move_dir.x != 0:
		out.x = min(abs(out.x) + acceleration, speed.x)
		out.x *= move_dir.x
	else:
		friction = true


	if is_on_floor():
		if friction == true:
			out.x = lerp(out.x, 0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0, air_cof)
	return out


func animate(move_dir):
	if speed != Vector2.ZERO:
		if move_dir == Vector2.LEFT:
			$AnimationPlayer.play("WalkLeft")
		if move_dir == Vector2.RIGHT:
			$AnimationPlayer.play("WalkRight")


func _on_Timer_timeout():
	if idle != true:
		wait(move_dir)
