extends Node

enum Jump {NORMAL, RUNNING}
var jump_type




onready var world = get_tree().get_root().get_node("World")
onready var pc = get_parent().get_parent().get_parent()
onready var mm = pc.get_node("MovementManager")
onready var sprite = pc.get_node("Sprite")
onready var guns = pc.get_node("GunManager/Guns")
onready var ap = pc.get_node("AnimationPlayer")
onready var anim = pc.get_node("AnimationManager")



func state_process():
	pc.move_dir.x = sign(mm.move_target.x - pc.position.x) #get direction to move
	pc.look_dir.x = pc.move_dir.x

	mm.velocity = get_velocity()
	var new_velocity = pc.move_and_slide_with_snap(mm.velocity, mm.snap_vector, mm.FLOOR_NORMAL, true)
	if pc.is_on_wall():
		new_velocity.y = max(mm.velocity.y, new_velocity.y)
		
	mm.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
	animate()


#	if pc.is_on_ceiling() and mm.bonk_timeout.time_left == 0:
#		mm.bonk("bonk")

#	if pc.is_on_floor():
#		if mm.forgive_timer.time_left == 0:
#			mm.snap_vector = mm.SNAP_DIRECTION * mm.SNAP_LENGTH
#			if mm.bonk_timeout.time_left == 0:
#				mm.bonk("Land")
#		mm.forgive_timer.start(mm.forgiveness_time)


	if abs(mm.move_target.x - pc.position.x) < 1: #when within one pixel
		pc.move_dir.x = 0
#		if pc.disabled:
#			mm.change_state("disabled")
#		else:
		#mm.change_state("run")
		print("moveto state clear")
		mm.change_state(mm.cached_state.name.to_lower())




func get_velocity():
	var out = mm.velocity
	out.y += mm.gravity * get_physics_process_delta_time()
	out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
	return out



func animate():
	var blend_time = 0
	
	var animation = "run"
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
	
	
	
	if animation == "run" or animation == "crouch_run":
		ap.playback_speed = max((abs(mm.velocity.x)/mm.speed.x) * 2, 0.1)
	else:
		ap.playback_speed = 1
	
	anim.set_gun_draw_index()
	sprite.frame_coords.y = vframe
	guns.position = anim.get_gun_pos(animation, vframe, sprite.frame_coords.x) #changes the gun sprite every time animate is called



func enter():
	pass
	
func exit():
	pc.move_dir.x = 0
	mm.velocity = Vector2.ZERO
	mm.move_target = Vector2.ZERO
