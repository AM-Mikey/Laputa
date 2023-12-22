extends Enemy

@export var start_dir = Vector2.LEFT

var move_dir

func _ready():
	hp = 3
	reward = 2
	damage_on_contact = 2
	speed = Vector2(60, 60)
	gravity = 200
	move_dir = start_dir
	animate()
	
	
	
func _physics_process(delta):
	if disabled or dead:
		return
	velocity = calculate_movevelocity(velocity, move_dir, speed)
	set_velocity(velocity)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	velocity = velocity

	if is_on_wall():
		move_dir *= -1
		animate()

func calculate_movevelocity(linearvelocity: Vector2, move_dir: Vector2, speed: Vector2) -> Vector2:
	var out: = linearvelocity
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
			out.x = lerp(out.x, 0.0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0.0, air_cof)
	return out

func animate():
	match move_dir:
		Vector2.LEFT: $AnimationPlayer.play("RollLeft")
		Vector2.RIGHT: $AnimationPlayer.play("RollRight")
