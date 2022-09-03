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
	
	
	if pc.is_on_ceiling(): #and mm.bonk_timeout.time_left == 0:
		mm.bonk("bonk")

	if pc.is_on_floor(): #landed
		mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
		mm.bonk("Land")
		mm.change_state("run")


func set_player_directions():
	var input_dir = Vector2(\
	Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),\
	Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	
	#get move dir
	pc.move_dir = Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0)
	
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



func get_velocity():
	var out = mm.velocity
	var friction = false

	out.y += mm.gravity * get_physics_process_delta_time()

	if pc.move_dir.x != 0:
		out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
	else:
		friction = true

	if friction:
		out.x = lerp(out.x, 0, mm.air_cof)

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
		ap.play(animation)
		ap.playback_speed = 1
	
	
	var vframe: int
	if pc.look_dir.x < 0: #left
		vframe = 0
		guns.flip_h = false
	else: #right
		vframe = 3
		guns.flip_h = true
	
	
	if pc.shoot_dir.y < 0: #up
		vframe += 1
		guns.rotation_degrees = 90 if not guns.scale.x == 1 else -90
	elif pc.shoot_dir.y > 0: #down
		vframe += 2
		guns.rotation_degrees = -90 if not guns.scale.x == 1 else 90
	else:
		guns.rotation_degrees = 0

	anim.set_gun_draw_index()
	sprite.frame_coords.y = vframe
	guns.position = anim.get_gun_pos(animation, vframe, sprite.frame_coords.x) #changes the gun sprite every time animate is called

func enter():
	pass
	
func exit():
	pass
