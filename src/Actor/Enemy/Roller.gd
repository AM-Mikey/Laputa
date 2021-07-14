extends Enemy

export var start_dir = Vector2.LEFT

var move_dir

func _ready():
	hp = 3
	level = 2
	damage_on_contact = 2
	speed = Vector2(60, 60)
	gravity = 200
	
	level = 1
	
	move_dir = start_dir
	animate()
	
	
	
func _physics_process(delta):
	if not dead:
		_velocity = calculate_move_velocity(_velocity, move_dir, speed)
		_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
	
		if is_on_wall():
			move_dir *= -1
			animate()

func calculate_move_velocity(linear_velocity: Vector2, move_dir: Vector2, speed: Vector2) -> Vector2:
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

func animate():
	match move_dir:
		Vector2.LEFT: $AnimationPlayer.play("RollLeft")
		Vector2.RIGHT: $AnimationPlayer.play("RollRight")
