extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")

var holding_jump = true

func state_process(_delta):
	# Jump holding
	if pc.can_input and not Input.is_action_pressed("jump"):
		holding_jump = false

	set_player_directions()
	pc.velocity = calc_velocity()
	pc.move_and_slide()

	animate()

	# We only set move_dir.y to jump for a single frame
	pc.move_dir.y = 0.0

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
	pc.move_dir = Vector2(input_dir.x, pc.move_dir.y)
	
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

func calc_velocity():
	var out = pc.velocity
	#Y
	# The player's move dir is vertically up. This happens only for a single frame
	if sign(pc.move_dir.y) == -1:
		out.y = mm.speed.y * pc.move_dir.y
	# Otherwise, perform gravity calculations
	else:
		out.y += mm.gravity * get_physics_process_delta_time()
		if not holding_jump and pc.velocity.y < 0.0:
			out.y *= 0.9
	#X
	if pc.move_dir.x != 0.0:
		var value = out.x + mm.acceleration * pc.move_dir.x
		# Make sure the acceleration does not surpass max speed
		out.x = clampf(value, -mm.speed.x, mm.speed.x)
	else: #air friction slide
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



### STATES ###			#TODO: juniper's hurtbox becomes much smaller when jumping

func enter():
	pc.get_node("CollisionShape2D").set_deferred("disabled", true)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("JumpCollision").set_deferred("disabled", false)
	pc.get_node("SSPDetector/CollisionShape2D2").set_deferred("disabled", false)
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.mm.snap_vector = Vector2.ZERO
	holding_jump = pc.can_input and Input.is_action_pressed("jump")
	if holding_jump:
		# Set the player's move dir to -1.0 to indicate a jump.
		# It will be reset on next physics frame
		pc.move_dir.y = -1.0
		am.play("pc_jump")

func exit():
	pc.mm.land()
	pc.get_node("CollisionShape2D").set_deferred("disabled", false)
	pc.get_node("CrouchingCollision").set_deferred("disabled", true)
	pc.get_node("JumpCollision").set_deferred("disabled", true)
	pc.get_node("SSPDetector/CollisionShape2D2").set_deferred("disabled", true)
