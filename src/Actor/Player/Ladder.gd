extends Node


var speed = Vector2(90,180)
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


	if pc.is_on_floor() and not pc.is_on_ssp:
		if Input.is_action_pressed("look_down"):
			pc.is_on_ladder = false
			mm.change_state(mm.states["normal"])
		


	pc.velocity = get_move_velocity(pc.velocity, pc.move_dir)
	var new_velocity = pc.move_and_slide_with_snap(pc.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap



func get_move_dir():
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
		)



func get_move_velocity(velocity, move_dir):
	var out = velocity
	
	

	out.y = move_dir.y * pc.speed.y * 0.5
	out.x = 0
	if Input.is_action_just_pressed("jump"):
		pc.is_on_ladder = false
		mm.change_state(mm.states["normal"])
		out.y = pc.speed.y * -1.0



	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
		
	return out





func enter():
	pc.speed = speed
	mm.snap_vector = Vector2.ZERO
	pc.set_collision_mask_bit(9, false) #ssp
	
func exit():
	pc.set_collision_mask_bit(9, true) #ssp
