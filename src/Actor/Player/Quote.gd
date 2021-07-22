extends Player


func _physics_process(delta):
	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0
	var is_dodge_interrupted: = Input.is_action_just_released("dodge") and _velocity.y < 0.0
	var move_direction = get_move_direction()
	var look_direction = get_look_direction()
	var special_direction = get_special_direction(move_direction, look_direction)

	if Input.is_action_just_pressed("dodge") and $Timer.time_left == 0:
		$Timer.start(dodge_time)

	_velocity = calculate_move_velocity(_velocity, move_direction, look_direction, special_direction, speed, is_jump_interrupted, is_dodge_interrupted)
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
	
	animate(move_direction, look_direction)
	
	if Input.is_action_just_pressed("shoot"):
		weapon_array[0].fire_weapon(look_direction)
	
	debug_print(move_direction, look_direction)

func get_move_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 0.0
		)

func get_look_direction() -> Vector2:
	if $Sprite.frame_coords.y == 0:
		return Vector2(-1, Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	else:
		return Vector2(1, Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))


func get_special_direction(move_direction, look_direction) -> Vector2:
	if Input.is_action_pressed("dodge"):
		return Vector2(look_direction.x * -1, -1.0)
	else:
		return Vector2.ZERO
	

func calculate_move_velocity(
		linear_velocity: Vector2,
		move_direction: Vector2,
		look_direction: Vector2,
		special_direction: Vector2,
		speed: Vector2,
		is_jump_interrupted: bool,
		is_dodge_interrupted: bool
		) -> Vector2:
	
	var out: = linear_velocity
	
	if special_direction == Vector2.ZERO:
		out.x = speed.x * move_direction.x
		out.y += gravity * get_physics_process_delta_time()
		if move_direction.y == -1.0:
			out.y = speed.y * move_direction.y
		if is_jump_interrupted:
			out.y = 0.0
	else:
		out.x = special_direction.x * dodge_speed.x * ($Timer.time_left)
		#out.x += (200 * (special_direction.x * -1)) * (5 - $Timer.time_left)
		print($Timer.time_left)
		out.y += gravity * get_physics_process_delta_time()
		if special_direction.y == -1.0 and $Timer.time_left != 0:
			out.y = special_direction.y * dodge_speed.y * ($Timer.time_left)
		#if special_direction.x == abs(1):
		if is_dodge_interrupted:
			out.x = 0.0
			out.y = 0.0
			
	return out
	
func animate(move_direction, look_direction):
	if move_direction.x == -1.0:
		$Sprite.frame_coords.y = 0
	if move_direction.x == 1.0:
		$Sprite.frame_coords.y = 1

	if is_on_floor():
		if Input.is_action_pressed("move_left"):
			$AnimationPlayer.play("move_left")
		elif Input.is_action_pressed("move_right"):
			$AnimationPlayer.play("move_right")
		else:
			$AnimationPlayer.stop(true)
			if look_direction.y < 0:
				$Sprite.frame_coords.x = 3
			elif look_direction.y > 0:
				$Sprite.frame_coords.x = 7
			else:
				$Sprite.frame_coords.x = 0
	else:
		$AnimationPlayer.stop(true)
		$Sprite.frame_coords.x = 2
