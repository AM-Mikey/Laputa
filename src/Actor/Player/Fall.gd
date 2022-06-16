extends Node

onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Juniper")
onready var mm = pc.get_node("MovementManager")

func state_process():
	pc.move_dir = get_move_dir()
	mm.velocity = get_velocity()
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
	return Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0)



func get_velocity():
	var out = mm.velocity
	var friction = false

	out.y += mm.gravity * get_physics_process_delta_time()

	if pc.move_dir.x != 0:
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
