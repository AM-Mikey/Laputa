extends Node





onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Juniper")
onready var mm = pc.get_node("MovementManager")

func state_process():
	#jump interrupt
	var is_jump_interrupted = false
	if mm.velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		is_jump_interrupted = true

	pc.move_dir = get_move_dir()
	mm.velocity = get_velocity(is_jump_interrupted)
	var new_velocity = pc.move_and_slide_with_snap(mm.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap



	if pc.is_on_ceiling(): #and mm.bonk_timeout.time_left == 0:
		mm.bonk("bonk")

	if pc.is_on_floor(): #landed
		mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
		mm.bonk("Land")
		mm.change_state(mm.states["run"])



func get_move_dir():
	var out_y = 0
	if mm.coyote_timer.time_left > 0:
		mm.coyote_timer.stop()
		out_y = -1
	if pc.is_on_floor():
		out_y = -1
	
	return Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), out_y)



func get_velocity(is_jump_interrupted):
	var out = mm.velocity
	var friction = false
	out.y += mm.gravity * get_physics_process_delta_time()
	
	if pc.move_dir.y < 0:
		out.y = mm.speed.y * pc.move_dir.y
	
	if is_jump_interrupted:
		out.y += mm.gravity * get_physics_process_delta_time()
	
	if pc.move_dir.x != 0: #left or right
		out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
	else:
		friction = true
	
	if friction:
		out.x = lerp(out.x, 0, mm.air_cof)

	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0

	return out





func enter():
	pass
	
func exit():
	pass
