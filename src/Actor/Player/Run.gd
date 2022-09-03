extends Node

onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Juniper")
onready var mm = pc.get_node("MovementManager")
onready var sprite = pc.get_node("Sprite")
onready var guns = pc.get_node("GunManager/Guns")
onready var ap = pc.get_node("AnimationPlayer")
onready var anim = pc.get_node("AnimationManager")

func state_process():
	set_player_directions()
	mm.velocity = get_velocity()
	var new_velocity = pc.move_and_slide_with_snap(mm.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)

	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	animate()
	
	
	if Input.is_action_just_pressed("jump"):
		mm.jump()
	
	if not pc.is_on_floor() and not pc.is_in_coyote:
		pc.is_in_coyote = true
		mm.do_coyote_time()


func set_player_directions():
	var input_dir = Vector2(\
	Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),\
	Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	
	#get move_dir
	pc.move_dir = Vector2(input_dir.x, 0)
	
	#get look_dir
	if pc.move_dir.x != 0:
		pc.look_dir = Vector2(pc.move_dir.x, input_dir.y)
	else:
		pc.look_dir = Vector2(pc.look_dir.x, input_dir.y)
	if pc.direction_lock != Vector2.ZERO:
		pc.look_dir = pc.direction_lock
	
	#get shoot_dir
	if pc.is_on_ssp:
		if pc.look_dir.y != 0: #up or down
			pc.shoot_dir = Vector2(0, pc.look_dir.y)
		else:
			pc.shoot_dir = pc.look_dir
	else:
		if pc.look_dir.y < 0: #up
			pc.shoot_dir = Vector2(0, pc.look_dir.y) 
		pc.shoot_dir = Vector2(pc.look_dir.x, min(pc.look_dir.y, 0)) #no look down




func get_velocity():
	var out = mm.velocity
	var friction = false

	out.y += mm.gravity * get_physics_process_delta_time()

	if pc.move_dir.x != 0:
		out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
	else:
		friction = true

	if friction:
		out.x = lerp(out.x, 0, mm.ground_cof)

	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
		
	return out


func animate():
	var blend_time = 0
	
	
	var animation = "run"
	if pc.direction_lock != Vector2.ZERO and pc.direction_lock.x != pc.move_dir.x:
		animation = "back_run"
	if pc.is_crouching:
		animation = "crouch_run"
	if pc.move_dir.x == 0: #abs(mm.velocity.x) < mm.min_x_velocity:
		animation = "stand"


	
	if not ap.is_playing() or ap.current_animation != animation:
		for g in anim.blend_array:
			if g.has(animation) and g.has(ap.current_animation):
				print("blending")
				blend_time = ap.current_animation_position #only blend certain animations
		ap.play(animation)
		ap.seek(blend_time)

	
	
	var vframe: int
	if pc.look_dir.x < 0: #left
		vframe = 0
		guns.scale.x = 1
	else: #right
		vframe = 4
		guns.scale.x = -1
	
	
	if pc.shoot_dir.y < 0: #up
		vframe += 1

		guns.rotation_degrees = 90 if not guns.scale.x == 1 else -90
	elif pc.shoot_dir.y > 0: #down
		vframe += 2

		guns.rotation_degrees = -90 if not guns.scale.x == 1 else 90
	elif pc.shoot_dir.y == 0 and pc.look_dir.y > 0: #look down, don't shoot down
		vframe += 3
		guns.rotation_degrees = 0
	else:
		guns.rotation_degrees = 0
	
	if animation == "run" or animation == "crouch_run" or animation == "back_run":
		ap.playback_speed = max((abs(mm.velocity.x)/mm.speed.x) * 2, 0.1)
	else:
		ap.playback_speed = 1
	
	anim.set_gun_draw_index()
	sprite.frame_coords.y = vframe
	guns.position = anim.get_gun_pos(animation, vframe, sprite.frame_coords.x) #changes the gun sprite every time animate is called





func enter():
	pass
func exit():
	pass
