extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")

var saved_move_dir := Vector2.ZERO #for the 2 frame stand
var do_edge_turn: bool
var push_left_wall := false
var push_right_wall := false

func state_process(_delta):
	set_player_directions()
	pc.velocity = calc_velocity()
	
	if pc.get_node("WallLB").is_colliding() or pc.get_node("WallLT").is_colliding():
		push_left_wall = true
		pc.velocity.x = max(pc.velocity.x, 0)
	else: push_left_wall = false
	if pc.get_node("WallRB").is_colliding() or pc.get_node("WallRT").is_colliding():
		push_right_wall = true
		pc.velocity.x = min(pc.velocity.x, 0)
	else: push_right_wall = false
	
	pc.move_and_slide()
	animate()
	
	
	if not pc.is_on_floor() and not pc.is_in_coyote:
		pc.is_in_coyote = true
		mm.do_coyote_time()
	if Input.is_action_pressed("jump") and pc.can_input:
		mm.jump()
		return

func set_player_directions():
	var input_dir = Vector2.ZERO
	if pc.can_input: 
		input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	#get move_dir
	pc.move_dir = Vector2(input_dir.x, 0.0)
	#get look_dir
	var look_x = pc.look_dir.x
	if pc.direction_lock != Vector2i.ZERO: #dir lock
		look_x = pc.direction_lock.x
	elif pc.move_dir.x != 0.0: #moving
		look_x = sign(pc.move_dir.x)
	pc.look_dir = Vector2i(look_x, input_dir.y)
	#get shoot_dir
	var shoot_vertically = false
	if pc.look_dir.y < 0.0 or (pc.look_dir.y > 0.0 and check_ssp()):
		shoot_vertically = true
	#if (!pc.get_node("EdgeLeft").get_collider() and pc.get_node("AbsoluteRight").get_collider() and pc.look_dir.x == -1.0 and pc.look_dir.y != 0) or (!pc.get_node("EdgeRight").get_collider() and pc.get_node("AbsoluteLeft").get_collider() and pc.look_dir.x == 1.0 and pc.look_dir.y != 0):
		#shoot_vertically = true
	if shoot_vertically: 
		pc.shoot_dir = Vector2(0.0, pc.look_dir.y) 
	else: 
		pc.shoot_dir = Vector2(pc.look_dir.x, 0.0)


func check_ssp() -> bool: #not the only thing that determines if can shoot down
	var out = false
	var SSP_raycast = pc.get_node("GunManager/SSP")
	match pc.look_dir.x:
		-1: SSP_raycast.global_position = pc.get_node("GunManager/GunPosLeftDown").global_position
		1: SSP_raycast.global_position = pc.get_node("GunManager/GunPosRightDown").global_position
	var length = abs(SSP_raycast.position.y) + 12
	SSP_raycast.target_position = Vector2(0.0, length)
	if !SSP_raycast.is_colliding():
		out = true
	print("PPPOASPDFOIASPOID", out)
	return out

func animate():
	sprite.position = Vector2i(0.0, -16.0)
	sprite.gun_pos_offset = Vector2.ZERO
	var animation = "run"
	var reference_texture = preload("res://assets/Player/Run.png")
	
	var absolute_left = pc.get_node("AbsoluteLeft").get_collider()
	var absolute_right = pc.get_node("AbsoluteRight").get_collider()
	var stand_close_left = pc.get_node("StandCloseLeft").get_collider()
	var stand_close_right = pc.get_node("StandCloseRight").get_collider()
	var edge_left = pc.get_node("EdgeLeft").get_collider()
	var edge_right = pc.get_node("EdgeRight").get_collider()
	var slight_slope_left = pc.get_node("SlightSlopeLeft").get_collider()
	var slight_slope_right = pc.get_node("SlightSlopeRight").get_collider()
	var slope_left = pc.get_node("SlopeLeft").get_collider()
	var slope_right = pc.get_node("SlopeRight").get_collider()
	

	
	
	if pc.direction_lock != Vector2i.ZERO and pc.direction_lock.x != sign(pc.move_dir.x):
		animation = "back_run"
		reference_texture = preload("res://assets/Player/BackRun.png")
	if pc.move_dir.x == 0.0 and saved_move_dir.x == 0.0: #standing
		
		if (!absolute_left and !absolute_right): #only a middle colliding
				do_edge_turn = false
				sprite.position = Vector2i(0.0, -15.0) #1 down
				animation = "stand_peak"
				reference_texture = preload("res://assets/Player/StandPeak.png")
		elif (!absolute_left and absolute_right and slight_slope_left) or (!absolute_right and absolute_left and slight_slope_right):
			do_edge_turn = false
			sprite.position = Vector2i(0.0, -12.0)
			if (!absolute_left and pc.look_dir.x == 1.0) or (!absolute_right and pc.look_dir.x == -1.0):
				animation = "slight_up_slope"
				reference_texture = preload("res://assets/Player/SlightUpSlope.png")
			else:
				animation = "slight_down_slope"
				reference_texture = preload("res://assets/Player/SlightDownSlope.png")
		elif (!absolute_left and absolute_right and slope_left) or (!absolute_right and absolute_left and slope_right):
			do_edge_turn = false
			if (!absolute_left and pc.look_dir.x == 1.0) or (!absolute_right and pc.look_dir.x == -1.0):
				sprite.position = Vector2i(0.0, -7.0)
				animation = "up_slope"
				reference_texture = preload("res://assets/Player/UpSlope.png")
			else:
				sprite.position = Vector2i(0.0, -9.0)
				animation = "down_slope"
				reference_texture = preload("res://assets/Player/DownSlope.png")
		elif (!edge_left and absolute_right and pc.look_dir.x == 1.0) or (!edge_right and absolute_left and pc.look_dir.x == -1.0):
			if do_edge_turn:
				animation = "edge_turn"
				reference_texture = preload("res://assets/Player/EdgeTurn.png")
			else:
				animation = "edge_front"
				reference_texture = preload("res://assets/Player/EdgeFront.png")
		elif (!stand_close_left and absolute_right and pc.look_dir.x == 1.0) or (!stand_close_right and edge_left and pc.look_dir.x == -1.0):
			animation = "stand_peak"
			reference_texture = preload("res://assets/Player/StandPeak.png")
		elif (!edge_left and pc.look_dir.x == -1.0) or (!edge_right and pc.look_dir.x == 1.0):
			do_edge_turn = true
			animation = "edge"
			reference_texture = preload("res://assets/Player/Edge.png")
		elif (!stand_close_left and pc.look_dir.x == -1.0) or (!stand_close_right and pc.look_dir.x == 1.0):
			do_edge_turn = false
			animation = "stand_close"
			reference_texture = preload("res://assets/Player/StandClose.png")
		else:
			do_edge_turn = false
			animation = "stand"
			reference_texture = preload("res://assets/Player/Stand.png")
	elif push_left_wall or push_right_wall:
		animation = "push"
		reference_texture = preload("res://assets/Player/Push.png")
	else: #running
		if (!absolute_left and absolute_right and slight_slope_left) or (!absolute_right and absolute_left and slight_slope_right): #run on slight slope
			sprite.position = Vector2i(0.0, -13.0)
			sprite.gun_pos_offset = Vector2(0, 3)
		elif (!absolute_left and absolute_right and slope_left) or (!absolute_right and absolute_left and slope_right): #run on slope
			sprite.position = Vector2i(0.0, -12.0)
			sprite.gun_pos_offset = Vector2(0, 4)
	
	
	if pc.is_crouching:
		if pc.move_dir.x == 0.0 and saved_move_dir.x == 0.0:
			animation = "crouch"
			reference_texture = preload("res://assets/Player/Crouch.png")
		elif abs(pc.velocity.x) <= 5.0 and pc.is_on_floor():
			animation = "push"
			reference_texture = preload("res://assets/Player/Push.png")
		else:
			animation = "crouch_run"
			reference_texture = preload("res://assets/Player/CrouchRun.png")

	#for runtime, set the frame counts before the animation starts
	sprite.hframes = int(reference_texture.get_width() / 32.0)
	sprite.vframes = int(reference_texture.get_height() / 32.0)

	ap.speed_scale = 1.0
	var do_blending = false
	
	var run_group = ["run", "crouch_run", "back_run"]
	#var edge_group = ["edge", "edge_front"]
	var stand_group = ["stand", "stand_close", "push", "crouch", "edge_turn", "up_slope", "down_slope", "slight_up_slope", "slight_down_slope", "stand_peak"]
	
	if run_group.has(animation):
		ap.speed_scale = max((abs(pc.velocity.x)/mm.speed.x) * 2, 0.1)
		if run_group.has(ap.current_animation):
			do_blending = true
	if stand_group.has(animation):
		if stand_group.has(ap.current_animation):
			do_blending = true

	var vframe = get_vframe()
	sprite.frame_coords.y = vframe


	var blend_time = 0.0
	if not ap.is_playing() or ap.current_animation != animation:
		if do_blending:
			#print("blending animation")
			if (ap.current_animation == "back_run" and animation == "run") or (ap.current_animation == "run" and animation == "back_run"): #special blend rules
				var new_frame = ((12 - int(floor(ap.current_animation_position * 10))) % 12) + 1
				blend_time = new_frame / 10.0
				#print("blending run from: ",ap.current_animation_position, ", to: ", blend_time)
			else:
				blend_time = ap.current_animation_position #only blend certain animations
			
		ap.stop()
		ap.play(animation, blend_time, 1.0)
		if blend_time != 0.0:
			ap.seek(blend_time, true)
	
	saved_move_dir = pc.move_dir #for 2 frame stand



### GETTERS ###

func calc_velocity():
	var out = pc.velocity
	#Y
	out.y += mm.gravity * get_physics_process_delta_time()
	#X
	if pc.move_dir.x != 0.0:
		var max_speed = mm.speed.x
		if pc.is_crouching:
			max_speed = mm.crouch_speed

		if pc.move_dir.x != sign(out.x):
			out.x = 0.0

		var value = out.x + mm.acceleration * pc.move_dir.x
		# Make sure the acceleration does not surpass max speed
		out.x = clampf(value, -max_speed, max_speed)
	# ground friction kicks in if you let go of a directional key
	else:
		out.x = lerp(out.x, 0.0, mm.ground_cof)
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
	return out


func get_vframe() -> int:
	var out = 0
	if sprite.vframes == 8:
		match pc.look_dir.x:
			-1: out = 0
			1: out = 4
		if pc.shoot_dir.y < 0.0:
			out += 1
		elif pc.shoot_dir.y > 0.0:
			out += 2
		elif pc.shoot_dir.y == 0.0 and pc.look_dir.y == 1:
			out += 3
	if sprite.vframes == 6:
		match pc.look_dir.x:
			-1: out = 0
			1: out = 3
		if pc.shoot_dir.y < 0.0:
			out += 1
		elif pc.shoot_dir.y > 0.0:
			out += 2
	return out



### STATE ###

func enter(): #TODO: consider setting these back after exiting or just set these on setup
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.floor_snap_length = 8.0
	pc.floor_max_angle = 0.8 #well over 45degrees so we can have a lower safe_margin
	pc.safe_margin = 0.008 #may cause issues this low
	do_edge_turn = false
func exit():
	sprite.position = Vector2i(0.0, -16.0)
