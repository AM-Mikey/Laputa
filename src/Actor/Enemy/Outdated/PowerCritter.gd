extends Enemy

var target = null

var jump_delay = 3
var move_dir = Vector2.ZERO

func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(60, 120)
	gravity = 200

	reward = 2

func _physics_process(delta):
	if not dead and not disabled:
		if not is_on_floor():
			move_dir.y = 0 #don't allow them to jump if they are midair
		
		if $Timer.time_left != 0 and is_on_floor(): #don't allow them to move x if they are not jumping
			move_dir.x = 0
		
		if $Timer.time_left == 0 and target != null and is_on_floor():
			$Timer.start(jump_delay)
			move_dir = get_move_dir()

		velocity = get_movevelocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)



func _on_PlayerDetector_body_entered(body):
	target = body


func _on_PlayerDetector_body_exited(_body):
	if is_on_floor():
		target = null
	else:
		add_child(timer)
	$Timer.one_shot = true
	$Timer.start(1)
	yield($Timer, "timeout")
	target = null


func get_move_dir() -> Vector2:
	return Vector2(sign(target.get_global_position().x - global_position.x), -1)


func get_movevelocity(
		linearvelocity: Vector2,
		move_direction: Vector2,
		speed: Vector2
		) -> Vector2:
	
	var out: = linearvelocity
	out.x = speed.x * move_direction.x
	out.y += gravity * get_physics_process_delta_time()
	if move_direction.y < 0:
		out.y = speed.y * move_direction.y
	return out
