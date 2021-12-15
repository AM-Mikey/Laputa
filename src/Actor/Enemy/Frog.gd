extends Enemy

var target = null

var jump_delay = 3
var move_dir = Vector2.ZERO
var look_dir = Vector2.LEFT

func _ready():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(12, 120)
	gravity = 200
	
	level = 2

func _physics_process(_delta):
	if not dead and not disabled:
		if not is_on_floor():
			move_dir.y = 0 #don't allow them to jump if they are midair
		
		if $Timer.time_left != 0 and is_on_floor(): #don't allow them to move x if they are not jumping
			move_dir.x = 0
			if target != null: #get look direction when not jumping
				look_dir = Vector2(get_move_dir().x, 0)

		if $Timer.time_left == 0 and target != null and is_on_floor():
			$Timer.start(jump_delay)
			$PosJump.play()
			move_dir = get_move_dir()
			look_dir = Vector2(move_dir.x, 0)

		velocity = get_movevelocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL, true)
		
		animate()

func _on_PlayerDetector_body_entered(body):
	target = body

func _on_PlayerDetector_body_exited(_body):
	target = null

func get_move_dir() -> Vector2:
	return Vector2(sign(target.get_global_position().x - global_position.x), -1)

func get_movevelocity(
		linearvelocity: Vector2,
		move_direction: Vector2,
		speed: Vector2
		) -> Vector2:
	
	var out: = linearvelocity
	var friction = false
	
	if is_in_water: #this code has no acceleration
		out.y += (gravity/2) * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = (speed.y * 0.75) * move_dir.y
		if move_dir.x != 0:
			out.x = speed.x * move_direction.x
		else:
			friction = true
	
	else: #this code has no acceleration
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = speed.y * move_dir.y
		if move_dir.x != 0:
			out.x = speed.x * move_direction.x
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
	if look_dir == Vector2.LEFT:
		if is_on_floor():
			if not $Timer.is_stopped() and $Timer.time_left <= 0.8:
				$AnimationPlayer.play("CroakLeft")
			else:
				$AnimationPlayer.play("StandLeft")
		else:
			if move_dir.y < 0:
				$AnimationPlayer.play("RiseLeft")
			elif move_dir.y > 0:
				$AnimationPlayer.play("FallLeft")

				
	elif look_dir == Vector2.RIGHT:
		if is_on_floor():
			if not $Timer.is_stopped() and $Timer.time_left <= 0.8:
				$AnimationPlayer.play("CroakRight")
			else:
				$AnimationPlayer.play("StandRight")
		else:
			if move_dir.y < 0:
				$AnimationPlayer.play("RiseRight")
			elif move_dir.y > 0:
				$AnimationPlayer.play("FallRight")

	
