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
var is_dropping = false

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
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("look_down") and pc.is_on_ssp and pc.can_input:
		is_dropping = true
		mm.drop()
		return
	elif Input.is_action_pressed("jump") and !is_dropping and pc.can_input:
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
	if pc.look_dir.y < 0.0:
		shoot_vertically = true
	if pc.look_dir.y > 0.0:
		if check_shoot_down():
			shoot_vertically = true
	
	if shoot_vertically: 
		pc.shoot_dir = Vector2(0.0, pc.look_dir.y) 
	else: 
		pc.shoot_dir = Vector2(pc.look_dir.x, 0.0)


func check_shoot_down() -> bool:
	var out = false
	var shoot_down_raycast = pc.get_node("GunManager/ShootDown")
	match pc.look_dir.x:
		-1: shoot_down_raycast.global_position = pc.get_node("GunManager/GunPosLeftDown").global_position
		1: shoot_down_raycast.global_position = pc.get_node("GunManager/GunPosRightDown").global_position
	var length = abs(shoot_down_raycast.position.y) + 12
	shoot_down_raycast.target_position = Vector2(0.0, length)
	if !shoot_down_raycast.is_colliding():
		out = true
	return out

func animate():
	#sprite.position = Vector2i(0.0, -16.0)
	#sprite.gun_pos_offset = Vector2.ZERO
	var animation = []
	#var reference_texture
	
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
	

	#var edge_connections = ["edge_turn", "run"]
	#var edge_turn_connections = ["edge", "run"]
	#var connected_animations = {
		#"edge": ["edge_turn", "run"],
		#"edge_turn": ["edge", "run"],
		#"edge_front": ["edge", "run"],
		#"push": ["stand", "up_slope", "down_slope", "slight_up_slope", "slight_down_slope"],
	#}
	
	
	var look_left = pc.look_dir.x == -1.0
	var look_right = pc.look_dir.x == 1.0
	
	var edge_condition = (!absolute_left and !edge_left and !slight_slope_right and !slope_right and absolute_right and look_left) or (absolute_left and !slope_left and !slight_slope_left and !edge_right and !absolute_left and look_right)
	var stand_condition = (stand_close_left and absolute_right and look_left) or (absolute_left and stand_close_right and look_right) or (absolute_left and edge_right and look_left) or (edge_left and absolute_right and look_right)
	
	var slight_up_condition = (absolute_left and slight_slope_left and !edge_left and !absolute_right and look_left) or (!absolute_left and !edge_right and slight_slope_right and absolute_right and look_right)
	var slight_down_condition = (!absolute_left and !edge_right and slight_slope_right and absolute_right and look_left) or (absolute_left and slight_slope_left and !edge_left and !absolute_right and look_right)
	var up_condition = (absolute_left and slope_left and !edge_left and !absolute_right and look_left) or (!absolute_left and !edge_right and slope_right and absolute_right and look_right)
	var down_condition = (!absolute_left and !edge_right and slope_right and absolute_right and look_left) or (absolute_left and slope_left and !edge_left and !absolute_right and look_right)
	
	match ap.current_animation: #do not use elif here
		"edge":
			if edge_condition:
				animation.append("edge")
			if (!edge_right and absolute_left and look_left) or (!edge_left and absolute_right and look_right):
				animation.append("edge_turn")
			if (edge_left and !stand_close_left and look_left) or (edge_right and !stand_close_right and look_right):
				animation.append("stand_close")
			
			if pc.move_dir.x != 0.0 and animation == []: #last case
				animation.append("run")

		"edge_turn":
			if edge_condition:
				animation.append("edge")
			if (!stand_close_right and absolute_left and look_left) or (!stand_close_left and absolute_right and look_right):
				animation.append("edge_turn")
			if (edge_left and !stand_close_left and look_left) or (edge_right and !stand_close_right and look_right):
				animation.append("stand_close")
			if stand_close_left and stand_close_right: #exception to condition
				animation.append("stand")
			
			
			if pc.move_dir.x != 0.0 and animation == []: #last case
				animation.append("run")
		"stand":
			if (edge_left and !stand_close_left and look_left) or (edge_right and !stand_close_right and look_right):
				animation.append("stand_close")
			
			if pc.move_dir.x != 0.0 and animation == []: #last case... add room for velocity 
				if push_left_wall or push_right_wall:
					animation.append("push")
				else:
					animation.append("run")
		
		"stand_close":
			if stand_condition:
				animation.append("stand") #TODO: when this goes to stand it goes right to run next frame if turn to make this happen, before returning to stand.
			if (edge_left and !stand_close_left and look_left) or (edge_right and !stand_close_right and look_right):
				animation.append("stand_close")
			if edge_condition:
				animation.append("edge")
			
			if pc.move_dir.x != 0.0 and animation == []: #last case
				animation.append("run")
		
		"push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("stand")
	
		"run":
			if pc.move_dir.x == 0.0: #not moving
				if (edge_left and absolute_right and !stand_close_left and look_left) or (absolute_left and edge_right and !stand_close_right and look_right):
					animation.append("stand_close")
				if edge_condition:
					animation.append("edge")
				if stand_condition:
					animation.append("stand")
				if !absolute_left and !absolute_right:
					animation.append("stand_peak")
				if slight_up_condition:
					animation.append("slight_up_slope")
				if slight_down_condition:
					animation.append("slight_down_slope")
				if up_condition:
					animation.append("up_slope")
				if down_condition:
					animation.append("down_slope")
			else:
				if push_left_wall or push_right_wall:
					if slight_up_condition:
						animation.append("slight_up_push")
					elif slight_down_condition:
						animation.append("slight_down_push")
					elif up_condition:
						animation.append("up_push")
					elif down_condition:
						animation.append("down_push")
					else:
						animation.append("push")
		
		"stand_peak":
			if pc.move_dir.x != 0.0 and animation == []: #last case
				animation.append("run")
		
		"slight_up_slope":
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("slight_up_push")
				else:
					animation.append("run")
		
		"slight_down_slope":
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("slight_down_push")
				else:
					animation.append("run")
		
		"up_slope":
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("up_push")
				else:
					animation.append("run")
		
		"down_slope":
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("down_push")
				else:
					animation.append("run")

		"slight_up_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("slight_up_slope")
		
		"slight_down_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("slight_down_slope")

		"up_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("up_slope")
		
		"down_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("down_slope")
	
	#if pc.direction_lock != Vector2i.ZERO and pc.direction_lock.x != sign(pc.move_dir.x):
		#animation = "back_run"
		#reference_texture = preload("res://assets/Player/BackRun.png")
	#if pc.move_dir.x == 0.0 and saved_move_dir.x == 0.0: #standing
		#
		#if (!absolute_left and !absolute_right): #only a middle colliding
				#do_edge_turn = false
				#sprite.position = Vector2i(0.0, -15.0) #1 down
				#animation = "stand_peak"
				#reference_texture = preload("res://assets/Player/StandPeak.png")
		#elif (!absolute_left and absolute_right and slight_slope_left) or (!absolute_right and absolute_left and slight_slope_right):
			#do_edge_turn = false
			#sprite.position = Vector2i(0.0, -12.0)
			#if (!absolute_left and pc.look_dir.x == 1.0) or (!absolute_right and pc.look_dir.x == -1.0):
				#animation = "slight_up_slope"
				#reference_texture = preload("res://assets/Player/SlightUpSlope.png")
			#else:
				#animation = "slight_down_slope"
				#reference_texture = preload("res://assets/Player/SlightDownSlope.png")
		#elif (!absolute_left and absolute_right and slope_left) or (!absolute_right and absolute_left and slope_right):
			#do_edge_turn = false
			#if (!absolute_left and pc.look_dir.x == 1.0) or (!absolute_right and pc.look_dir.x == -1.0):
				#sprite.position = Vector2i(0.0, -7.0)
				#animation = "up_slope"
				#reference_texture = preload("res://assets/Player/UpSlope.png")
			#else:
				#sprite.position = Vector2i(0.0, -9.0)
				#animation = "down_slope"
				#reference_texture = preload("res://assets/Player/DownSlope.png")
		#elif (!edge_left and absolute_right and pc.look_dir.x == 1.0) or (!edge_right and absolute_left and pc.look_dir.x == -1.0):
			#if do_edge_turn:
				#animation = "edge_turn"
				#reference_texture = preload("res://assets/Player/EdgeTurn.png")
			#else:
				#animation = "edge_front"
				#reference_texture = preload("res://assets/Player/EdgeFront.png")
		#elif (!stand_close_left and absolute_right and pc.look_dir.x == 1.0) or (!stand_close_right and edge_left and pc.look_dir.x == -1.0):
			#animation = "stand_peak"
			#reference_texture = preload("res://assets/Player/StandPeak.png")
		#elif (!edge_left and pc.look_dir.x == -1.0) or (!edge_right and pc.look_dir.x == 1.0):
			#do_edge_turn = true
			#animation = "edge"
			#reference_texture = preload("res://assets/Player/Edge.png")
		#elif (!stand_close_left and pc.look_dir.x == -1.0) or (!stand_close_right and pc.look_dir.x == 1.0):
			#do_edge_turn = false
			#animation = "stand_close"
			#reference_texture = preload("res://assets/Player/StandClose.png")
		#else:
			#do_edge_turn = false
			#animation = "stand"
			#reference_texture = preload("res://assets/Player/Stand.png")
	#elif push_left_wall or push_right_wall:
		#animation = "push"
		#reference_texture = preload("res://assets/Player/Push.png")
	#else: #running
		#if (!absolute_left and absolute_right and slight_slope_left) or (!absolute_right and absolute_left and slight_slope_right): #run on slight slope #TODO: reimplement this position change!!!
			#sprite.position = Vector2i(0.0, -13.0)
			#sprite.gun_pos_offset = Vector2(0, 3)
		#elif (!absolute_left and absolute_right and slope_left) or (!absolute_right and absolute_left and slope_right): #run on slope
			#sprite.position = Vector2i(0.0, -12.0)
			#sprite.gun_pos_offset = Vector2(0, 4)
	#
	#
	#if pc.is_crouching:
		#if pc.move_dir.x == 0.0 and saved_move_dir.x == 0.0:
			#animation = "crouch"
			#reference_texture = preload("res://assets/Player/Crouch.png")
		#elif abs(pc.velocity.x) <= 5.0 and pc.is_on_floor():
			#animation = "push"
			#reference_texture = preload("res://assets/Player/Push.png")
		#else:
			#animation = "crouch_run"
			#reference_texture = preload("res://assets/Player/CrouchRun.png")


	if animation.is_empty():
		play_animation(ap.current_animation)
		return
	if animation.size() != 1:
		printerr("ERROR: CONFLICT SETTING RUN ANIMATION FROM ", ap.current_animation, " to ", animation)
		return
	#if animation[0] == ap.current_animation:
		#return
	do_animation_sprite_offset(animation[0])
	play_animation(animation[0])
	
	saved_move_dir = pc.move_dir #for 2 frame stand

func do_animation_sprite_offset(animation):
	var offsets = {
		"stand_peak": Vector2(0, 1),
		"slight_up_slope": Vector2(0, 4),
		"slight_down_slope": Vector2(0, 4),
		"up_slope": Vector2(0, 9),
		"down_slope": Vector2(0, 7),
		"slight_up_push": Vector2(0, 6),
		"slight_down_push": Vector2(0, 6),
		"up_push": Vector2(0, 9),
		"down_push": Vector2(0, 8),
	}
	sprite.position = Vector2i(0.0, -16.0)
	if offsets.has(animation):
		sprite.position += offsets[animation]


func play_animation(animation):
	#for runtime, set the frame counts before the animation starts
	var reference_texture = load("res://assets/Player/" + animation.to_pascal_case() + ".png")
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
	play_animation("run")
func exit():
	sprite.position = Vector2i(0.0, -16.0)
	is_dropping = false
