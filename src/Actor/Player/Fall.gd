extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")
@onready var anim = pc.get_node("AnimationManager")


func state_process():
	set_player_directions()
	mm.velocity = calc_velocity()
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
	var input_dir = Vector2(\
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),\
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	
	#get move dir
	pc.move_dir = Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0.0)
	
	#get look dir
	if pc.move_dir.x != 0.0:
		pc.look_dir = Vector2i(sign(pc.move_dir.x), input_dir.y)
	else:
		pc.look_dir = Vector2i(pc.look_dir.x, input_dir.y)
	if pc.direction_lock != Vector2i.ZERO:
		pc.look_dir = pc.direction_lock
	
	#get shoot dir
	if pc.is_on_ssp:
		if pc.look_dir.y != 0: #up or down
			pc.shoot_dir = Vector2(0.0, pc.look_dir.y)
		else:
			pc.shoot_dir = pc.look_dir


func animate():
	var animation: String
	var reference_texture = preload("res://assets/Actor/Player/AerialNew.png")
	var do_back = false
	if pc.direction_lock != Vector2i.ZERO and pc.direction_lock.x != sign(pc.velocity.x) and abs(pc.velocity.x) > 0.1:
		reference_texture = preload("res://assets/Actor/Player/BackAerialNew.png")
		do_back = true
	
	if abs(mm.velocity.y) < 20:
		animation = "back_aerial_top" if do_back else "aerial_top"
	elif mm.velocity.y < 0:
		animation = "back_aerial_rise" if do_back else "aerial_rise"
	elif mm.velocity.y > 0:
		animation = "back_aerial_fall" if do_back else "aerial_fall"
	
	#for runtime, set the frame counts before the animation starts
	sprite.hframes = int(reference_texture.get_width() / 32.0)
	sprite.vframes = int(reference_texture.get_height() / 32.0)
	
	var vframe = get_vframe()
	#anim.set_gun_draw_index()
	sprite.frame_coords.y = vframe
	#guns.position = anim.get_gun_pos(animation, vframe, sprite.frame_coords.x) #changes the gun sprite every time animate is called

	if not ap.is_playing() or ap.current_animation != animation:
		ap.stop()
		ap.play(animation, 0.0, 1.0)



### GETTERS ###

func calc_velocity():
	var out = mm.velocity
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
		-1:
			out = 0
			#guns.scale.x = 1.0
		1:
			out = 3
			#guns.scale.x = -1.0
	
	if pc.shoot_dir.y < 0.0:
			out += 1
			#guns.rotation_degrees = 90.0 if guns.scale.x == 1.0 else -90.0
	elif pc.shoot_dir.y > 0.0:
			out += 2
			#guns.rotation_degrees = -90.0 if guns.scale.x == 1.0 else 90.0
	#elif pc.shoot_dir.y == 0.0:
			#guns.rotation_degrees = 0
	return out



### STATES ###

func enter():
	pass
func exit():
	pass
