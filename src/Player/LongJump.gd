extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")

func state_process(_delta):
	#jump interrupt
	var is_jump_interrupted = false
	if pc.velocity.y < 0.0:
		if not Input.is_action_pressed("jump") and pc.can_input:
			is_jump_interrupted = true

	set_player_directions()
	pc.velocity = calc_velocity(is_jump_interrupted)
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.move_and_slide()
	var new_velocity = pc.velocity
	if pc.is_on_wall():
		new_velocity.y = max(pc.velocity.y, new_velocity.y)
		
	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	animate()

	if pc.is_on_floor(): #landed
		mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
		mm.change_state("run")
		return


func set_player_directions():
	var input_dir = Vector2.ZERO
	if pc.can_input: 
		input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	
	#get move dir
	var move_y = 0.0
	if mm.coyote_timer.time_left > 0.0:
		mm.coyote_timer.stop()
		move_y = -1.0
	if pc.is_on_floor():
		move_y = -1.0
	pc.move_dir = Vector2(input_dir.x, move_y)
	
	#get look_dir
	var look_x = pc.look_dir.x
	if pc.direction_lock != Vector2i.ZERO: #dir lock
		look_x = pc.direction_lock.x
	elif pc.move_dir.x != 0.0: #moving
		look_x = sign(pc.move_dir.x)
	pc.look_dir = Vector2i(look_x, input_dir.y)
	
	#get shoot dir
	if pc.look_dir.y != 0.0: #up/down
		pc.shoot_dir = Vector2(0.0, pc.look_dir.y) 
	else:
		pc.shoot_dir = Vector2(pc.look_dir.x, 0.0)


func animate():
	var animation: String
	var reference_texture = preload("res://assets/Player/Aerial.png")
	var do_back = false
	if pc.direction_lock != Vector2i.ZERO and pc.direction_lock.x != sign(pc.velocity.x) and abs(pc.velocity.x) > 0.1:
		reference_texture = preload("res://assets/Player/BackAerial.png")
		do_back = true
	
	if abs(pc.velocity.y) < 20:
		animation = "back_aerial_top" if do_back else "aerial_top"
	elif pc.velocity.y < 0:
		animation = "back_aerial_rise" if do_back else "aerial_rise"
	elif pc.velocity.y > 0:
		animation = "back_aerial_fall" if do_back else "aerial_fall"

	#for runtime, set the frame counts before the animation starts
	sprite.hframes = int(reference_texture.get_width() / 32.0)
	sprite.vframes = int(reference_texture.get_height() / 32.0)

	var vframe = get_vframe()
	sprite.frame_coords.y = vframe

	if not ap.is_playing() or ap.current_animation != animation:
		ap.stop()
		ap.play(animation, 0.0, 1.0)



### GETTERS ###

func calc_velocity(is_jump_interrupted):
	var out = pc.velocity
	#Y
	out.y += mm.gravity * get_physics_process_delta_time()
	if sign(pc.move_dir.y) == -1:
		out.y = mm.speed.y * pc.move_dir.y
	if is_jump_interrupted:
		out.y += mm.gravity * get_physics_process_delta_time()
	#X
	if sign(pc.move_dir.x) != mm.jump_starting_move_dir_x: #if we turn around, cancel min_dir_timer
		mm.min_dir_timer.stop()
#	if pc.is_on_wall(): #TODO: consider stopping min dir if we hit a wall #there are other problems here, like the fact we dont drop vel if we hit a wall
#		print("hit wall, cancelling")
#		mm.min_dir_timer.stop()
	if not mm.min_dir_timer.is_stopped(): #still doing min direction time
		out.x = mm.speed.x * mm.jump_starting_move_dir_x
	else: #min direction time bypassed
		if pc.move_dir.x != 0.0:
			if sign(pc.move_dir.x) != mm.jump_starting_move_dir_x: #if we're not facing out start dir, slow down
				out.x = min(abs(out.x) + mm.acceleration, (mm.speed.x * 0.5)) * pc.move_dir.x
			else:
				out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
		else:
			out.x = lerp(out.x, 0.0, mm.air_cof)
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
	return out


func get_vframe() -> int:
	var out = 0
	match pc.look_dir.x:
		-1: out = 0
		1: out = 3

	if pc.shoot_dir.y < 0.0:
		out += 1
	elif pc.shoot_dir.y > 0.0:
		out += 2
	return out



### STATE ###

func enter():
	pc.get_node("CollisionShape2D").set_deferred("disabled", true)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("JumpCollision").set_deferred("disabled", false)
	pc.get_node("SSPDetector/CollisionShape2D2").set_deferred("disabled", false)

func exit():
	pc.mm.land()
	pc.get_node("CollisionShape2D").set_deferred("disabled", false)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("JumpCollision").set_deferred("disabled", true)
	pc.get_node("SSPDetector/CollisionShape2D2").set_deferred("disabled", true)
