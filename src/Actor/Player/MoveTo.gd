extends Node

enum Jump {NORMAL, RUNNING}
var jump_type




onready var world = get_tree().get_root().get_node("World")
onready var pc = world.get_node("Juniper")
onready var mm = pc.get_node("MovementManager")
onready var sprite = pc.get_node("Sprite")
onready var gun_sprite = pc.get_node("GunSprite")
onready var ap = pc.get_node("AnimationPlayer")
onready var anim = pc.get_node("AnimationManager")



func state_process():
	pc.move_dir.x = sign(mm.move_target.x - pc.position.x) #get direction to move

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
		if pc.disabled:
			mm.change_state("disabled")
		else:
			mm.change_state("run")




func get_velocity():
	var out = mm.velocity
	out.y += mm.gravity * get_physics_process_delta_time()
	out.x = min(abs(out.x) + mm.acceleration, mm.speed.x) * pc.move_dir.x
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
		gun_sprite.flip_h = false
	else: #right
		vframe = 4
		gun_sprite.flip_h = true
#		gun_sprite.position.x = gun_sprite.position.x + 8
		
	
	
	
	
	if pc.shoot_dir.y < 0: #up
		vframe += 1

		gun_sprite.rotation_degrees = 90 if not gun_sprite.flip_h else -90
	elif pc.shoot_dir.y > 0: #down
		vframe += 2

		gun_sprite.rotation_degrees = -90 if not gun_sprite.flip_h else 90
	elif pc.shoot_dir.y == 0 and pc.look_dir.y > 0: #look down, don't shoot down
		vframe += 3
		gun_sprite.rotation_degrees = 0
	else:
		gun_sprite.rotation_degrees = 0
	
	if animation == "run" or animation == "crouch_run" or animation == "back_run":
		ap.playback_speed = max((abs(mm.velocity.x)/mm.speed.x) * 2, 0.1)
	else:
		ap.playback_speed = 1
	
	anim.set_gun_draw_index()
	sprite.frame_coords.y = vframe
	gun_sprite.position = anim.get_gun_pos(animation, vframe, sprite.frame_coords.x) #changes the gun sprite every time animate is called



func enter():
	pass
	
func exit():
	pc.move_dir.x = 0
	mm.velocity = Vector2.ZERO
	mm.move_target = Vector2.ZERO
