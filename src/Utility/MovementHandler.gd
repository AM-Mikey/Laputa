extends Node2D



func _physics_process(delta):
	parent = get_parent() # just in case node hierarchy changes for some reason
	
	
				velocity = get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted)
			var new_velocity = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, true)


func get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted) -> Vector2:
	var out = velocity
	
	var friction = false
	

	
	if is_in_water:
		out.y += (gravity/2) * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = (jump_speed * 0.75) * move_dir.y
		
		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, (max_x_speed/2))
			out.x *= move_dir.x
		else:
			friction = true

	else: #normal movement
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = jump_speed * move_dir.y

		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, max_x_speed)
			out.x *= move_dir.x
		else:
			friction = true



	if is_on_floor():
		if friction == true:
			out.x = lerp(out.x, 0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0, air_cof)


	if abs(out.x) < min_xvelocity:
		out.x = 0
	#print(out)
	return out
