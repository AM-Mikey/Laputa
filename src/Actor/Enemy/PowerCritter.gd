extends Enemy

var target = null

var jump_delay = 3
var move_direction = Vector2.ZERO
var player_direction = Vector2.ZERO

func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 100)


func _physics_process(delta):
	if not dead:
		if $Timer.time_left == 0 and target != null and is_on_floor():
			player_direction = get_player_direction(target)
		move_direction = get_move_direction(player_direction)
	
		
		_velocity = get_move_velocity(_velocity, move_direction, speed)
		_velocity = move_and_slide(_velocity, FLOOR_NORMAL)



func _on_PlayerDetector_body_entered(body):
	target = body


func _on_PlayerDetector_body_exited(body):
	if is_on_floor():
		target = null
	else:
		add_child(timer)
	timer.one_shot = true
	timer.start(1)
	yield(timer, "timeout")
	target = null

func get_player_direction(target):
	return Vector2(
	sign(target.get_global_position().x - global_position.x), 0)

func get_move_direction(player_direction) -> Vector2:
	if $Timer.time_left == 0  and target != null and is_on_floor():
		$Timer.start(jump_delay)
		return Vector2(player_direction.x, -1)
	elif target != null and not is_on_floor():
		return Vector2(player_direction.x, 0)
	else: 
		return Vector2.ZERO


func get_move_velocity(
		linear_velocity: Vector2,
		move_direction: Vector2,
		speed: Vector2
		) -> Vector2:
	
	var out: = linear_velocity
	out.x = speed.x * move_direction.x
	out.y += gravity * get_physics_process_delta_time()
	if move_direction.y < 0:
		out.y = speed.y * move_direction.y
	return out

func _input(event):
	if event.is_action_pressed("debug"):
		print($Timer.time_left)
		print($Timer.is_stopped())
		print("target", target)
		print("move direction", move_direction)
