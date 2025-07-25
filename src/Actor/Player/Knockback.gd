extends Node


@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")

func state_process():
	set_move_dir()
	if mm.knockback_velocity == Vector2.ZERO:
		mm.knockback_velocity = Vector2(mm.knockback_speed.x * mm.knockback_direction.x, mm.knockback_speed.y * -1)
		mm.velocity.y = mm.knockback_velocity.y #set knockback y to this ONCE

	mm.velocity.x += mm.knockback_velocity.x
	mm.velocity.x = min(abs(mm.velocity.x), mm.speed.x) * sign(mm.velocity.x)
	mm.knockback_velocity.x *= 0.5 #next frame it falls off

	if abs(mm.knockback_velocity.x) < 1:
		mm.knockback_velocity = Vector2.ZERO
		#pc.knockback = false
		#print("changing from kb to cached")
		mm.change_state(mm.cached_state.name.to_lower())
		return



	mm.velocity = get_move_velocity(mm.velocity, pc.move_dir)
	pc.set_velocity(mm.velocity)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `mm.snap_vector`
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.move_and_slide()
	var new_velocity = pc.velocity
		
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap

func set_move_dir():
	var move_dir = Vector2.ZERO
	if pc.can_input:
		move_dir= Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0.0)
		if mm.coyote_timer.time_left > 0.0 and Input.is_action_just_pressed("jump"):
			move_dir = Vector2(move_dir.x, -1.0)
	pc.move_dir = move_dir



### GETTERS ###

func get_move_velocity(velocity, move_dir):
	var out = velocity
	#Y
	out.y += mm.gravity * get_physics_process_delta_time()
	if sign(move_dir.y) == -1:
		out.y = mm.speed.y * pc.move_dir.y
	#X
	if move_dir.x != 0.0:
		out.x = min(abs(out.x) + mm.acceleration, mm.speed.x)
		out.x *= pc.move_dir.x
	return out



### STATES ###

func enter():
	pc.get_node("CollisionShape2D").set_deferred("disabled", true)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("JumpCollision").set_deferred("disabled", false)
	pc.get_node("SSPDetector/CollisionShape2D2").set_deferred("disabled", false)

func exit():
	pc.get_node("CollisionShape2D").set_deferred("disabled", false)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("JumpCollision").set_deferred("disabled", true)
	pc.get_node("SSPDetector/CollisionShape2D2").set_deferred("disabled", true)
