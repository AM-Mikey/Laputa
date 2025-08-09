extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")


func state_process(_delta):
	pc.velocity = get_move_velocity(pc.velocity)
	pc.move_and_slide()
	var new_velocity = pc.velocity
	if pc.is_on_wall():
		new_velocity.y = max(pc.velocity.y, new_velocity.y)
	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap



### GETTERS ###

func get_move_velocity(velocity):
	var out = velocity
	#Y
	out.y += mm.gravity * get_physics_process_delta_time()
	#X
	if pc.is_on_floor():
		out.x = lerp(out.x, 0.0, mm.ground_cof * 2)
	else:
		out.x = lerp(out.x, 0.0, mm.air_cof * 2)
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
	return out



### STATES ###

func enter():
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
func exit():
	pass
