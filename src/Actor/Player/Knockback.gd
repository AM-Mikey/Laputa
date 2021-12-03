extends Node


onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Recruit")
onready var mm = pc.get_node("MovementManager")

func state_process():
	pc.move_dir = get_move_dir()

	if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
		mm.bonk("bonk")
		
		
	if mm.knockback_velocity == Vector2.ZERO:
		mm.knockback_velocity = Vector2(mm.knockback_speed.x * mm.knockback_direction.x, mm.knockback_speed.y * -1)
		pc.velocity.y = mm.knockback_velocity.y #set knockback y to this ONCE

	pc.velocity.x += mm.knockback_velocity.x
	mm.knockback_velocity.x *= 0.5 #next frame it falls off

	if abs(mm.knockback_velocity.x) < 1:
		mm.knockback_velocity = Vector2.ZERO
		pc.knockback = false
		mm.change_state(mm.states["normal"])



	pc.velocity = get_move_velocity(pc.velocity, pc.move_dir)
	var new_velocity = pc.move_and_slide_with_snap(pc.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
		
	if pc.is_on_wall():
		new_velocity.y = max(pc.velocity.y, new_velocity.y)
		
	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap



func get_move_dir():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		
		-1.0 \
		if Input.is_action_just_pressed("jump") and mm.forgive_timer.time_left > 0 \
		or Input.is_action_just_pressed("jump") and pc.is_on_floor() 
		else 0.0)




func get_move_velocity(velocity, move_dir):
	var out = velocity
#	var friction = false
	
	


#	if jump_type == Jump.RUNNING:
#		out.y += mm.GRAVITY * get_physics_process_delta_time()
#		if move_dir.y < 0:
#			out.y = pc.speed.y * move_dir.y
#		if is_jump_interrupted:
#			out.y += mm.GRAVITY * get_physics_process_delta_time()
#
#		if move_dir.x == mm.jump_starting_move_dir_x *-1: #if we turn around, cancel minimumdirectiontimer
#			mm.min_dir_timer.stop()
#
#		if not mm.min_dir_timer.is_stopped():
#			out.x = pc.speed.x
#			out.x *= mm.jump_starting_move_dir_x
#
#
#		elif move_dir.x != 0: #try this as an "if" instead, if it's not working
#			if move_dir.x != mm.jump_starting_move_dir_x:
#				out.x = min(abs(out.x) + pc.acceleration, (pc.speed.x * 0.5))
#				out.x *= pc.move_dir.x
#				#$MinimumDirectionTimer.start(0)
#			else:
#				out.x = min(abs(out.x) + pc.acceleration, pc.speed.x)
#				out.x *= pc.move_dir.x
#		else:
#			friction = true
	
	
	#normal
#	else:
	out.y += mm.GRAVITY * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = pc.speed.y * pc.move_dir.y
	
#	if is_jump_interrupted:
#		out.y += mm.GRAVITY * get_physics_process_delta_time()

	if move_dir.x != 0:
		out.x = min(abs(out.x) + pc.acceleration, pc.speed.x)
		out.x *= pc.move_dir.x
#	else:
#		friction = true
	
	print(out)
	return out
	


func enter():
	pass
	
func exit():
	pass
