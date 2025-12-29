extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")


func state_process(_delta):
	set_player_directions()
	pc.velocity = calc_velocity()
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.move_and_slide()
	var new_velocity = pc.velocity
	if pc.is_on_wall(): #TODO migrate?
		new_velocity.y = max(pc.velocity.y, new_velocity.y)

	pc.velocity.y = min(mm.terminal_velocity, new_velocity.y) #only set y portion because we're doing move and slide with snap
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
	pc.move_dir = Vector2(input_dir.x, 0.0)

	#get look dir
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
	out.y += mm.gravity * get_physics_process_delta_time()
	#X
	if pc.move_dir.x != 0.0:
		out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
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



### STATES ###

func enter(_prev_state: String) -> void:
	var disable = [
		pc.get_node("CollisionShape2D"),
		pc.get_node("CrouchingCollision")]
	var enable = [
		pc.get_node("JumpCollision"),
		pc.get_node("SSPDetector/CollisionShape2D2")]
	mm.disable_collision_shapes(disable)
	mm.enable_collision_shapes(enable)


func exit(_next_state: String) -> void:
	pc.mm.land()
	var disable = [
		pc.get_node("CrouchingCollision"),
		pc.get_node("JumpCollision"),
		pc.get_node("SSPDetector/CollisionShape2D2")]
	var enable = [pc.get_node("CollisionShape2D")]
	mm.disable_collision_shapes(disable)
	mm.enable_collision_shapes(enable)
