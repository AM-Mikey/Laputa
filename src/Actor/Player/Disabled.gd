extends Node


onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Recruit")
onready var mm = pc.get_node("MovementManager")

func state_process():
	
	mm.velocity = get_move_velocity(mm.velocity)
	var new_velocity = pc.move_and_slide_with_snap(mm.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap




func get_move_velocity(velocity):
	var out = velocity
	
	out.y += mm.gravity * get_physics_process_delta_time()
	
	if pc.is_on_floor():
		out.x = lerp(out.x, 0, mm.ground_cof * 2)
	else:
		out.x = lerp(out.x, 0, mm.air_cof * 2)
	
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
		
	return out


func enter():
	pass
	
func exit():
	pass
