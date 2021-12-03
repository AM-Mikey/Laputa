extends Node

enum Jump {NORMAL, RUNNING}
var jump_type
var forgiveness_time = 0.05




onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Recruit")
onready var mm = pc.get_node("MovementManager")

func state_process():

	pc.move_dir = get_move_dir()

	if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
		mm.bonk("bonk")


	if pc.is_on_floor():
		jump_type = Jump.NORMAL
		
		
		if mm.forgive_timer.time_left == 0:
			mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
			if mm.bonk_timeout.time_left == 0:
				mm.bonk("Land")
		

		mm.forgive_timer.start(forgiveness_time)






	#jump interrupt
	var is_jump_interrupted = false
	if mm.velocity.y < 0.0:
		if not Input.is_action_pressed("jump"):
			is_jump_interrupted = true









	mm.velocity = get_move_velocity(mm.velocity, pc.move_dir, is_jump_interrupted)
	var new_velocity = pc.move_and_slide_with_snap(mm.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
		
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap



func get_move_dir():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		
		-1.0 \
		if Input.is_action_just_pressed("jump") and mm.forgive_timer.time_left > 0 \
		or Input.is_action_just_pressed("jump") and pc.is_on_floor() 
		else 0.0)





func get_move_velocity(velocity, move_dir, is_jump_interrupted):
	var out = velocity
	var friction = false
	
	
	
	
	out.y += mm.GRAVITY * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = mm.speed.y * move_dir.y
	
	if is_jump_interrupted:
		out.y += mm.GRAVITY * get_physics_process_delta_time()






	if jump_type == Jump.RUNNING:
		if move_dir.x != mm.jump_starting_move_dir_x: #if we turn around, cancel min_dir_timer
			mm.min_dir_timer.stop()
		
		if mm.min_dir_timer.is_stopped():
			#min direction bypassed
			if move_dir.x != 0:
				if move_dir.x != mm.jump_starting_move_dir_x: #if we're not facing out start dir, slow down
					out.x = min(abs(out.x) + mm.acceleration, (mm.speed.x * 0.5)) * pc.move_dir.x
				else:
					out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
			else:
				friction = true
			
		else: #still doing min direction time
			out.x = pc.speed.x * mm.jump_starting_move_dir_x
	
	
	
	else: #normal
		if move_dir.x != 0:
			out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
		else:
			friction = true





	if friction:
		if pc.is_on_floor():
			out.x = lerp(out.x, 0, mm.ground_cof)
		else:
			out.x = lerp(out.x, 0, mm.air_cof)


	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
		
	return out





func enter():
	pass
	
func exit():
	pass
