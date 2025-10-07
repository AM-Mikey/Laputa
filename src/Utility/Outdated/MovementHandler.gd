extends Node2D
#TODO: dont use this, its outdated


func _physics_process(delta):
	var parent = get_parent() # just in case node hierarchy changes for some reason
	
	
	velocity = get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted)
	set_velocity(velocity)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `snap_vector`
	set_up_direction(FLOOR_NORMAL)
	set_floor_stop_on_slope_enabled(true)
	move_and_slide()
	var new_velocity = velocity


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
			out.x = lerp(out.x, 0.0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0.0, air_cof)


	if abs(out.x) < min_xvelocity:
		out.x = 0
	#print(out)
	return out
