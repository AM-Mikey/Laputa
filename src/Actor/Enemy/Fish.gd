extends Enemy



func _ready():
	$AnimationPlayer.play("Idle")
	speed = Vector2(0, -100)


func jump():
	move_dir = Vector2.UP

func _physics_process(delta):
	if not is_in_water
	


		velocity = get_move_velocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)

func get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted) -> Vector2:
	var out = velocity

	
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = jump_speed * move_dir.y

