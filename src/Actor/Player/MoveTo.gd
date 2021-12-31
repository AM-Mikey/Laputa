extends Node

enum Jump {NORMAL, RUNNING}
var jump_type




onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Recruit")
onready var mm = pc.get_node("MovementManager")

func state_process():
	pc.move_dir.x = sign(mm.move_target.x - pc.position.x) #get direction to move


	if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
		mm.bonk("bonk")

	if pc.is_on_floor():
		if mm.forgive_timer.time_left == 0:
			mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
			if mm.bonk_timeout.time_left == 0:
				mm.bonk("Land")
		mm.forgive_timer.start(mm.forgiveness_time)



	mm.velocity = get_move_velocity(mm.velocity)
	var new_velocity = pc.move_and_slide_with_snap(mm.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
		
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap


	if abs(mm.move_target.x - pc.position.x) < 1: #when within one pixel
		pc.move_dir.x = 0
		if pc.disabled:
			mm.change_state(mm.states["disabled"])
		else:
			mm.change_state(mm.states["normal"])




func get_move_velocity(velocity):
	var out = velocity

	out.y += mm.gravity * get_physics_process_delta_time()
	out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x

	return out




func enter():
	pass
	
func exit():
	pc.move_dir.x = 0
	mm.velocity = Vector2.ZERO
	mm.move_target = Vector2.ZERO
