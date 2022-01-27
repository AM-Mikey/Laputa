extends Node


onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Juniper")
onready var mm = pc.get_node("MovementManager")

func state_process():
	pc.move_dir = get_move_dir()

	if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
		mm.bonk("bonk")
		
		
	if mm.knockback_velocity == Vector2.ZERO:
		mm.knockback_velocity = Vector2(mm.knockback_speed.x * mm.knockback_direction.x, mm.knockback_speed.y * -1)
		mm.velocity.y = mm.knockback_velocity.y #set knockback y to this ONCE

	mm.velocity.x += mm.knockback_velocity.x
	mm.knockback_velocity.x *= 0.5 #next frame it falls off

	if abs(mm.knockback_velocity.x) < 1:
		mm.knockback_velocity = Vector2.ZERO
		#pc.knockback = false
		mm.change_state(mm.states["normal"])



	mm.velocity = get_move_velocity(mm.velocity, pc.move_dir)
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




func get_move_velocity(velocity, move_dir):
	var out = velocity
	var friction = false

	out.y += mm.gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = mm.speed.y * pc.move_dir.y
	
#	if is_jump_interrupted:
#		out.y += mm.gravity * get_physics_process_delta_time()

	if move_dir.x != 0:
		out.x = min(abs(out.x) + mm.acceleration, mm.speed.x)
		out.x *= pc.move_dir.x
	else:
		friction = true
	
	print(out)
	return out
	


func enter():
	pass
	
func exit():
	pass
