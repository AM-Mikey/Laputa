extends Node


@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")

func state_process():
	
	mm.velocity = get_move_velocity(mm.velocity)
	pc.set_velocity(mm.velocity)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `mm.snap_vector`
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.move_and_slide()
	var new_velocity = pc.velocity
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap




func get_move_velocity(velocity):
	var out = velocity
	
	out.y += mm.gravity * get_physics_process_delta_time()
	
	if pc.is_on_floor():
		out.x = lerp(out.x, 0.0, mm.ground_cof * 2)
	else:
		out.x = lerp(out.x, 0.0, mm.air_cof * 2)
	
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
		
	return out


func enter():
	pass
	
func exit():
	pass
