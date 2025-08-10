extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")

var saved_move_dir := Vector2.ZERO #for the 2 frame stand

func state_process(_delta):
	set_player_directions()
	pc.velocity = calc_velocity()
	pc.move_and_slide()
	var new_velocity = pc.velocity
	if pc.is_on_wall(): #doesnt work while walking on ground
		new_velocity.y = max(pc.velocity.y, new_velocity.y)
	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	animate()

	#if Input.is_action_pressed("look_down") and pc.can_input: manual crouch
		#pc.is_crouching = true
		#pc.get_node("CollisionShape2D").set_deferred("disabled", true)
		#pc.get_node("CrouchingCollision").set_deferred("disabled", false)
	#elif not pc.is_forced_crouching:
		#pc.is_crouching = false
		#pc.get_node("CollisionShape2D").set_deferred("disabled", false)
		#pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	
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
	if pc.look_dir.y < 0.0 or (pc.look_dir.y > 0.0 and pc.is_on_ssp):
		shoot_vertically = true
	if (!pc.get_node("EdgeLeft").get_collider() and pc.get_node("AbsoluteRight").get_collider() and pc.look_dir.x == -1.0 and pc.look_dir.y != 0) or (!pc.get_node("EdgeRight").get_collider() and pc.get_node("AbsoluteLeft").get_collider() and pc.look_dir.x == 1.0 and pc.look_dir.y != 0):
		shoot_vertically = true
	if shoot_vertically: 
		pc.shoot_dir = Vector2(0.0, pc.look_dir.y) 
	else: 
		pc.shoot_dir = Vector2(pc.look_dir.x, 0.0)
	

func animate():
	var animation = "run"
	var reference_texture = preload("res://assets/Player/Run.png")
	if pc.direction_lock != Vector2i.ZERO and pc.direction_lock.x != sign(pc.move_dir.x):
		animation = "back_run"
		reference_texture = preload("res://assets/Player/BackRun.png")
	if pc.move_dir.x == 0.0 and saved_move_dir.x == 0.0:
		if (!pc.get_node("EdgeLeft").get_collider() and pc.get_node("AbsoluteRight").get_collider() and pc.look_dir.x == 1.0) or (!pc.get_node("EdgeRight").get_collider() and pc.get_node("AbsoluteLeft").get_collider() and pc.look_dir.x == -1.0):
			animation = "edge_turn"
			reference_texture = preload("res://assets/Player/EdgeTurn.png")
		elif (!pc.get_node("StandCloseLeft").get_collider() and pc.get_node("AbsoluteRight").get_collider() and pc.look_dir.x == 1.0) or (!pc.get_node("StandCloseRight").get_collider() and pc.get_node("AbsoluteLeft").get_collider() and pc.look_dir.x == -1.0):
			animation = "edge_turn"
			reference_texture = preload("res://assets/Player/EdgeTurn.png")
		elif (!pc.get_node("EdgeLeft").get_collider() and pc.look_dir.x == -1.0) or (!pc.get_node("EdgeRight").get_collider() and pc.look_dir.x == 1.0):
			animation = "edge"
			reference_texture = preload("res://assets/Player/Edge.png")
		elif (!pc.get_node("StandCloseLeft").get_collider() and pc.look_dir.x == -1.0) or (!pc.get_node("StandCloseRight").get_collider() and pc.look_dir.x == 1.0):
			animation = "stand_close"
			reference_texture = preload("res://assets/Player/StandClose.png")
		else:
			animation = "stand"
			reference_texture = preload("res://assets/Player/Stand.png")
	elif abs(pc.velocity.x) <= 5.0 and pc.is_on_floor():
		animation = "push"
		reference_texture = preload("res://assets/Player/Push.png")
	
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
	if animation == "run" or animation == "crouch_run" or animation == "back_run":
		ap.speed_scale = max((abs(pc.velocity.x)/mm.speed.x) * 2, 0.1)
		if ap.current_animation == "run" or ap.current_animation == "crouch_run" or ap.current_animation == "back_run":
			do_blending = true
	if animation == "stand" or animation == "stand_close" or animation == "push" or animation == "crouch" or animation == "edge_turn":
		if ap.current_animation == "stand" or ap.current_animation == "stand_close" or ap.current_animation == "push" or ap.current_animation == "crouch" or ap.current_animation == "edge_turn":
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
		if pc.is_crouching:
			out.x = min(abs(out.x) + mm.acceleration, mm.crouch_speed) * pc.move_dir.x
		else:
			out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
	else: #friction slide
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

func enter():
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
func exit():
	pass
