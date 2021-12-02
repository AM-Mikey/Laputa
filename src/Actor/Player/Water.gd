extends Node

enum Jump {NORMAL, RUNNING}
var jump_type
var forgiveness_time = 0.05

var speed = Vector2(60,140)
var acceleration = 2.5 #was 5
var ground_cof = 0.1 #was 0.2
var air_cof = 0.00 # was 0.05


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
	if pc.velocity.y < 0.0:
		if not Input.is_action_pressed("jump"):
			is_jump_interrupted = true









	pc.velocity = get_move_velocity(pc.velocity, pc.move_dir, is_jump_interrupted)
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






func get_move_velocity(velocity, move_dir, is_jump_interrupted):
	var out = velocity
	var friction = false
	
	



	if jump_type == Jump.RUNNING:
		out.y += mm.GRAVITY * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = pc.speed.y * move_dir.y
		if is_jump_interrupted:
			out.y += mm.GRAVITY * get_physics_process_delta_time()
		
		if move_dir.x == mm.jump_starting_move_dir_x *-1: #if we turn around, cancel minimumdirectiontimer
			mm.min_dir_timer.stop()
		
		if not mm.min_dir_timer.is_stopped():
			out.x = pc.speed.x
			out.x *= mm.jump_starting_move_dir_x
		
		
		elif move_dir.x != 0: #try this as an "if" instead, if it's not working
			if move_dir.x != mm.jump_starting_move_dir_x:
				out.x = min(abs(out.x) + pc.acceleration, (pc.speed.x * 0.5))
				out.x *= pc.move_dir.x
				#$MinimumDirectionTimer.start(0)
			else:
				out.x = min(abs(out.x) + pc.acceleration, pc.speed.x)
				out.x *= pc.move_dir.x
		else:
			friction = true
	
	

	else: 	#water stuff
		out.y += (mm.GRAVITY/2) * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = (pc.speed.y) * move_dir.y
		if is_jump_interrupted:
			out.y += (mm.GRAVITY/2) * get_physics_process_delta_time()

		if move_dir.x != 0:
			out.x = min(abs(out.x) + pc.acceleration, (pc.speed.x))
			out.x *= move_dir.x
		else:
			friction = true



	if friction:
		if pc.is_on_floor():
			out.x = lerp(out.x, 0, ground_cof)
	else:
		out.x = lerp(out.x, 0, air_cof)


	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
		
	return out





func enter():
	pc.speed = speed
	
func exit():
	pass
