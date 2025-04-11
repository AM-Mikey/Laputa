extends Node

enum Jump {NORMAL, RUNNING}
var jump_type




@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")



func state_process():
	pc.move_dir.x = mm.move_target.x - pc.position.x #get direction to move
	pc.look_dir.x = sign(pc.move_dir.x)

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


#	if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
#		mm.bonk("head")

#	if pc.is_on_floor():
#		if mm.forgive_timer.time_left == 0:
#			mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
#			if mm.bonk_timeout.time_left == 0:
#				mm.bonk("feet")
#		mm.forgive_timer.start(mm.forgiveness_time)


	if abs(mm.move_target.x - pc.position.x) < 1: #when within one pixel
		pc.move_dir.x = 0.0
#		if pc.disabled:
#			mm.change_state("disabled")
#		else:
		#mm.change_state("run")
		print("moveto state clear")
		mm.change_state(mm.cached_state.name.to_lower())
		return


func animate():
	var animation = "run"
	var reference_texture = preload("res://assets/Actor/Player/RunNew.png")
	if pc.direction_lock != Vector2i.ZERO and pc.direction_lock.x != sign(pc.move_dir.x):
		animation = "back_run"
		reference_texture = preload("res://assets/Actor/Player/BackRunNew.png")
	if pc.is_crouching:
		animation = "crouch_run"
		reference_texture = preload("res://assets/Actor/Player/CrouchRunNew.png")
	if pc.move_dir.x == 0.0: #abs(mm.velocity.x) < mm.min_x_velocity:
		animation = "stand"
		reference_texture = preload("res://assets/Actor/Player/StandNew.png")

	#for runtime, set the frame counts before the animation starts
	sprite.hframes = int(reference_texture.get_width() / 32.0)
	sprite.vframes = int(reference_texture.get_height() / 32.0)

	if animation == "run" or animation == "crouch_run" or animation == "back_run":
		ap.speed_scale = max((abs(mm.velocity.x)/mm.speed.x) * 2, 0.1)
	else:
		ap.speed_scale = 1.0

	#anim.set_gun_draw_index()
	var vframe = get_vframe()
	sprite.frame_coords.y = vframe
	#guns.position = anim.get_gun_pos(animation, vframe, sprite.frame_coords.x) #changes the gun sprite every time animate is called


	var blend_time = 0.0
	if not ap.is_playing() or ap.current_animation != animation:
		#for group in anim.blend_array: TODO: fix?
			#if group.has(animation) and group.has(ap.current_animation):
				#print("blending animation")
				#blend_time = ap.current_animation_position #only blend certain animations
		ap.stop()
		ap.play(animation, blend_time, 1.0)



### GETTERS ###

func calc_velocity():
	var out = mm.velocity
	out.y += mm.gravity * get_physics_process_delta_time()
	out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
	return out

func get_vframe() -> int:
	var out = 0
	match pc.look_dir.x:
		-1: out = 0
		1: out = 4

	if pc.shoot_dir.y < 0.0:
		out += 1
	elif pc.shoot_dir.y > 0.0:
		out += 2
	elif pc.shoot_dir.y == 0.0 and pc.look_dir.y == 1:
		out += 3
	return out



### STATE ###

func enter():
	pass
func exit():
	pc.move_dir.x = 0.0
	mm.velocity = Vector2.ZERO
	mm.move_target = Vector2.ZERO
