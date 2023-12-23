extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")
@onready var anim = pc.get_node("AnimationManager")

func state_process():
	#jump interrupt
	var is_jump_interrupted = false
	if mm.velocity.y < 0.0:
		if not Input.is_action_pressed("jump") and pc.controller_id == 0 or \
		not Input.is_action_pressed("sasuke_jump") and pc.controller_id == 1:
			is_jump_interrupted = true

	set_player_directions()
	mm.velocity = calc_velocity(is_jump_interrupted)
	pc.set_velocity(mm.velocity)
	# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `mm.snap_vector`
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.move_and_slide()
	var new_velocity = pc.velocity
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	animate()


	#if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
		#mm.bonk("head")

	if pc.is_on_floor(): #landed
		mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
		#mm.bonk("feet")
		mm.change_state("run")

func set_player_directions():
	var input_dir: Vector2
	match pc.controller_id:
		#juniper
		0: input_dir = Vector2(\
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),\
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
		#sasuke
		1: input_dir = Vector2(\
			Input.get_action_strength("sasuke_right") - Input.get_action_strength("sasuke_left"),\
			Input.get_action_strength("sasuke_down") - Input.get_action_strength("sasuke_up"))
	
	#get move dir
	var out_y = 0.0
	if mm.coyote_timer.time_left > 0:
		mm.coyote_timer.stop()
		out_y = -1.0
	if pc.is_on_floor():
		out_y = -1.0
	pc.move_dir = Vector2(input_dir.x, out_y)
	
	#get look dir
	if pc.move_dir.x != 0:
		pc.look_dir = Vector2(pc.move_dir.x, input_dir.y)
	else:
		pc.look_dir = Vector2(pc.look_dir.x, input_dir.y)
	if pc.direction_lock != Vector2.ZERO:
		pc.look_dir = pc.direction_lock
	
	#get shoot dir
	if pc.is_on_ssp:
		if pc.look_dir.y != 0: #up or down
			pc.shoot_dir = Vector2(0, pc.look_dir.y)
		else:
			pc.shoot_dir = pc.look_dir



func calc_velocity(is_jump_interrupted):
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
		out.x = lerp(out.x, 0.0, mm.air_cof)

	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0

	return out




func animate():
	var animation: String
	
	if abs(mm.velocity.y) < 20:
		animation = "aerial_top"
	elif mm.velocity.y < 0:
		animation = "aerial_rise"
	elif mm.velocity.y > 0:
		animation = "aerial_fall"
	
	if not ap.is_playing() or ap.current_animation != animation:
		ap.play(animation, 0.0, 1.0)
	
	
	var vframe: int
	if pc.look_dir.x < 0: #left
		vframe = 0
		guns.scale.x = 1
	else: #right
		vframe = 3
		guns.scale.x = -1
	
	
	if pc.shoot_dir.y < 0: #up
		vframe += 1
		guns.rotation_degrees = 90 if guns.scale.x == 1 else -90
	elif pc.shoot_dir.y > 0: #down
		vframe += 2
		guns.rotation_degrees = -90 if guns.scale.x == 1 else 90
	else:
		guns.rotation_degrees = 0
	
	
	
	anim.set_gun_draw_index()
	sprite.frame_coords.y = vframe
	guns.position = anim.get_gun_pos(animation, vframe, sprite.frame_coords.x) #changes the gun sprite every time animate is called



func enter():
	pass
	
func exit():
	pass
