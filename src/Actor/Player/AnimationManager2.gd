extends Node

enum Layer {BACK, FRONT, BOTH}


onready var pc = get_tree().get_root().get_node("World/Juniper")
onready var mm = pc.get_node("MovementManager")
onready var ap = pc.get_node("AnimationPlayer")



var gun_pos_dict = {

	"stand" : [
			{0: Vector2(-7,-12)},
			{0: Vector2(-3,-16)},
			{0: Vector2(-5,-7)},
			{0: Vector2(-7,-12)},
			{0: Vector2(1,-10)},
			{0: Vector2(-1,-16)},
			{0: Vector2(0,-7)},
			{0: Vector2(1,-10)},
			],
	"run" : [
			{0: Vector2(-7,-9), 3: Vector2(-6,-9), 4: Vector2(-5,-9), 9: Vector2(-6,-9), 10: Vector2(-7,-9)},
			{0: Vector2(-5,-16), 1: Vector2(-5,-14), 2: Vector2(-5,-15), 5: Vector2(-5,-14), 6: Vector2(-5,-13), 7: Vector2(-5,-11), 8: Vector2(-5,-12), 9: Vector2(-5,-14), 10: Vector2(-5,-16)},
			{0: Vector2(-3,-6), 1: Vector2(-3,-5), 2: Vector2(-3,-6), 4: Vector2(-3,-7), 6: Vector2(-3,-6), 7: Vector2(-3,-5), 8: Vector2(-3,-6), 10: Vector2(-3,-7)},
			{0: Vector2(-7,-9), 3: Vector2(-6,-9), 4: Vector2(-5,-9), 9: Vector2(-6,-9), 10: Vector2(-7,-9)},
			{0: Vector2(1,-9), 3: Vector2(2,-9), 4: Vector2(3,-9), 9: Vector2(2,-9), 10: Vector2(1,-9)},
			{0: Vector2(1,-13), 1: Vector2(1,-11), 2: Vector2(1,-12), 3: Vector2(1,-14), 4: Vector2(1,-16), 6: Vector2(1,-16), 7: Vector2(1,-14), 8: Vector2(1,-15), 11: Vector2(1,-14)},
			{0: Vector2(3,-6), 1: Vector2(3,-5), 2: Vector2(3,-6), 4: Vector2(3,-7), 6: Vector2(3,-6), 7: Vector2(3,-5), 8: Vector2(3,-6), 10: Vector2(3,-7)},
			{0: Vector2(1,-9), 3: Vector2(2,-9), 4: Vector2(3,-9), 9: Vector2(2,-9), 10: Vector2(1,-9)},
			],
	"crouch_run" : [
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(-5,-14), 1: Vector2(-5,-12), 2: Vector2(-5,-13), 5: Vector2(-5,-12), 6: Vector2(-5,-11), 7: Vector2(-5,-9), 8: Vector2(-5,-10), 9: Vector2(-5,-12), 10: Vector2(-5,-14)},
			{0: Vector2(-3,-4), 1: Vector2(-3,-3), 2: Vector2(-3,-4), 4: Vector2(-3,-5), 6: Vector2(-3,-4), 7: Vector2(-3,-3), 8: Vector2(-3,-4), 10: Vector2(-3,-5)},
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			{0: Vector2(1,-11), 1: Vector2(1,-9), 2: Vector2(1,-10), 3: Vector2(1,-12), 4: Vector2(1,-14), 6: Vector2(1,-14), 7: Vector2(1,-12), 8: Vector2(1,-13), 11: Vector2(1,-12)},
			{0: Vector2(3,-4), 1: Vector2(3,-3), 2: Vector2(3,-4), 4: Vector2(3,-5), 6: Vector2(3,-4), 7: Vector2(3,-3), 8: Vector2(3,-4), 10: Vector2(3,-5)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			],
	"aerial_rise" : [
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(-5,-14), 1: Vector2(-5,-12), 2: Vector2(-5,-13), 5: Vector2(-5,-12), 6: Vector2(-5,-11), 7: Vector2(-5,-9), 8: Vector2(-5,-10), 9: Vector2(-5,-12), 10: Vector2(-5,-14)},
			{0: Vector2(-3,-4), 1: Vector2(-3,-3), 2: Vector2(-3,-4), 4: Vector2(-3,-5), 6: Vector2(-3,-4), 7: Vector2(-3,-3), 8: Vector2(-3,-4), 10: Vector2(-3,-5)},
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			{0: Vector2(1,-11), 1: Vector2(1,-9), 2: Vector2(1,-10), 3: Vector2(1,-12), 4: Vector2(1,-14), 6: Vector2(1,-14), 7: Vector2(1,-12), 8: Vector2(1,-13), 11: Vector2(1,-12)},
			{0: Vector2(3,-4), 1: Vector2(3,-3), 2: Vector2(3,-4), 4: Vector2(3,-5), 6: Vector2(3,-4), 7: Vector2(3,-3), 8: Vector2(3,-4), 10: Vector2(3,-5)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			],
	"aerial_top" : [
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(-5,-14), 1: Vector2(-5,-12), 2: Vector2(-5,-13), 5: Vector2(-5,-12), 6: Vector2(-5,-11), 7: Vector2(-5,-9), 8: Vector2(-5,-10), 9: Vector2(-5,-12), 10: Vector2(-5,-14)},
			{0: Vector2(-3,-4), 1: Vector2(-3,-3), 2: Vector2(-3,-4), 4: Vector2(-3,-5), 6: Vector2(-3,-4), 7: Vector2(-3,-3), 8: Vector2(-3,-4), 10: Vector2(-3,-5)},
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			{0: Vector2(1,-11), 1: Vector2(1,-9), 2: Vector2(1,-10), 3: Vector2(1,-12), 4: Vector2(1,-14), 6: Vector2(1,-14), 7: Vector2(1,-12), 8: Vector2(1,-13), 11: Vector2(1,-12)},
			{0: Vector2(3,-4), 1: Vector2(3,-3), 2: Vector2(3,-4), 4: Vector2(3,-5), 6: Vector2(3,-4), 7: Vector2(3,-3), 8: Vector2(3,-4), 10: Vector2(3,-5)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			],
	"aerial_fall" : [
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(-5,-14), 1: Vector2(-5,-12), 2: Vector2(-5,-13), 5: Vector2(-5,-12), 6: Vector2(-5,-11), 7: Vector2(-5,-9), 8: Vector2(-5,-10), 9: Vector2(-5,-12), 10: Vector2(-5,-14)},
			{0: Vector2(-3,-4), 1: Vector2(-3,-3), 2: Vector2(-3,-4), 4: Vector2(-3,-5), 6: Vector2(-3,-4), 7: Vector2(-3,-3), 8: Vector2(-3,-4), 10: Vector2(-3,-5)},
			{0: Vector2(-7,-7), 3: Vector2(-6,-7), 4: Vector2(-5,-7), 9: Vector2(-6,-7), 10: Vector2(-7,-7)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			{0: Vector2(1,-11), 1: Vector2(1,-9), 2: Vector2(1,-10), 3: Vector2(1,-12), 4: Vector2(1,-14), 6: Vector2(1,-14), 7: Vector2(1,-12), 8: Vector2(1,-13), 11: Vector2(1,-12)},
			{0: Vector2(3,-4), 1: Vector2(3,-3), 2: Vector2(3,-4), 4: Vector2(3,-5), 6: Vector2(3,-4), 7: Vector2(3,-3), 8: Vector2(3,-4), 10: Vector2(3,-5)},
			{0: Vector2(1,-7), 3: Vector2(2,-7), 4: Vector2(3,-7), 9: Vector2(2,-7), 10: Vector2(1,-7)},
			],
}


func get_gun_pos(sheet_name: String, animation_index: int, frame_index: int) -> Vector2:
	var gun_pos = Vector2.ZERO
	var sheet_data = gun_pos_dict[sheet_name]
	
	var animation_data = sheet_data[animation_index]
	
	if animation_data.has(frame_index):
		gun_pos = animation_data[frame_index]
	else:
		var keys = animation_data.keys()
		for k in keys:
			if k < frame_index: #should find the highest frame lower than the frame index
				gun_pos = animation_data[k]
	
	return gun_pos


#func _physics_process(_delta):
#	animate()
#
#
#func animate():
#	var next_animation: String = ""
#	var start_time: float
#	var run_anim_speed = max((abs(mm.velocity.x)/mm.speed.x) * 2, 0.1)
#	var climb_anim_speed = mm.velocity.y / (mm.speed.y * 0.5)
#
#
#
#	if mm.current_state == mm.states["ladder"]:
#		ap.playback_speed = climb_anim_speed
#		if get_input_dir().x != 0:
#			next_animation = get_next_animation("Climb", get_input_dir(), true)
#		else:
#			next_animation = get_next_animation("Climb", pc.face_dir, true)
#
#
#	else: #normal animation
#		if pc.direction_lock == Vector2.ZERO:  #NOT DIRECTION LOCKED
#
#			if pc.is_on_floor():
#
#				if get_input_dir().x != 0:
#					ap.playback_speed = run_anim_speed
#					next_animation = get_next_animation("Run", get_input_dir(), pc.is_on_ssp)
#				else:
#					ap.playback_speed = 1
#					match pc.inspecting:
#						true: next_animation = get_next_animation("Reverseidle", pc.face_dir, true)
#						false: next_animation = get_next_animation("Stand", pc.face_dir, pc.is_on_ssp)
#
#
#			else: #arial
#				ap.playback_speed = 0
#
#				if get_input_dir() == Vector2.LEFT or get_input_dir() == Vector2.RIGHT:
#					next_animation = get_next_animation("Arial", get_input_dir(), true)
#				else:
#					next_animation = get_next_animation("Arial", pc.face_dir, true)
#
#				if mm.velocity.y < 0: 		#Rising
#					start_time = 0
#				elif mm.velocity.y == 0:	#Zenith
#					start_time = 0.1
#				else: 						#Falling
#					start_time = 0.2
#
#
#
#		elif pc.direction_lock == Vector2.LEFT: #DIRECTION LOCKED LEFT
#			pc.face_dir = Vector2.LEFT
#
#			if pc.is_on_floor():
#				if get_input_dir().x == -1:
#					ap.playback_speed = run_anim_speed
#					next_animation = get_next_animation("Run", Vector2.LEFT, pc.is_on_ssp)
#				elif get_input_dir().x == 1:
#					ap.playback_speed = run_anim_speed
#					next_animation = get_next_animation("Backrun", Vector2.RIGHT, pc.is_on_ssp)
#				else:
#					ap.playback_speed = 1
#					match pc.inspecting:
#						true: next_animation = get_next_animation("Reverseidle", pc.face_dir, true)
#						false: next_animation = get_next_animation("Stand", pc.face_dir, pc.is_on_ssp)
#
#
#			else: #arial
#				ap.playback_speed = 0
#
#				if get_input_dir().x == -1:
#					next_animation = get_next_animation("Arial", Vector2.LEFT, true)
#				elif get_input_dir().x == 1:
#					next_animation = get_next_animation("Arial", Vector2.LEFT, true) #TODO backarial
#				else:
#					next_animation = get_next_animation("Arial", pc.face_dir, true)
#
#				if mm.velocity.y < 0: 		#Rising
#					start_time = 0
#				elif mm.velocity.y == 0:	#Zenith
#					start_time = 0.1
#				else: 						#Falling
#					start_time = 0.2
#
#
#		elif pc.direction_lock == Vector2.RIGHT: #DIRECTION LOCKED RIGHT
#			pc.face_dir = Vector2.RIGHT
#
#			if pc.is_on_floor():
#				if get_input_dir().x == -1:
#					ap.playback_speed = run_anim_speed
#					next_animation = get_next_animation("Backrun", Vector2.LEFT, pc.is_on_ssp)
#				elif get_input_dir().x == 1:
#					ap.playback_speed = run_anim_speed
#					next_animation = get_next_animation("Run", Vector2.RIGHT, pc.is_on_ssp)
#				else:
#					ap.playback_speed = 1
#					match pc.inspecting:
#						true: next_animation = get_next_animation("Reverseidle", pc.face_dir, true)
#						false: next_animation = get_next_animation("Stand", pc.face_dir, pc.is_on_ssp)
#
#
#			else: #arial
#				ap.playback_speed = 0
#
#				if get_input_dir().x == -1:
#					next_animation = get_next_animation("Arial", Vector2.RIGHT, true)
#				elif get_input_dir().x == 1:
#					next_animation = get_next_animation("Arial", Vector2.RIGHT, true) #TODO backarial
#				else:
#					next_animation = get_next_animation("Arial", pc.face_dir, true)
#
#				if mm.velocity.y < 0: 		#Rising
#					start_time = 0
#				elif mm.velocity.y == 0:	#Zenith
#					start_time = 0.1
#				else: 						#Falling
#					start_time = 0.2
#
#
#
#
#
#
#	if (ap.current_animation != next_animation \
#	or (ap.current_animation == next_animation and start_time)) and next_animation != "":
#		change_animation(next_animation, start_time)
#
#
#
#func get_input_dir() -> Vector2:
#	if not pc.disabled:
#		return Vector2(
#			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
#			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
#	else:
#		return Vector2(
#			pc.move_dir.x if mm.current_state == mm.states["moveto"] else 0,
#			0)
#
#
#
#func get_next_animation(animation, anim_dir, can_shoot_down):
#	var animation_suffix
#	var gs = get_parent().get_node("GunSprite")
#
#	pc.face_dir = anim_dir
#	pc.shoot_dir = Vector2(anim_dir.x, 0)
#	gs.rotation_degrees = 0
#
#	if anim_dir.x == -1:
#		animation_suffix = ".L"
#		gs.scale.x = 1
#	elif anim_dir.x == 1:
#		animation_suffix = ".R"
#		gs.scale.x = -1
#
#
#	if not "Climb" in animation: #climbing doesnt look up or down so skip this section
#		if get_input_dir().y == -1:
#			animation_suffix += "1"
#			pc.shoot_dir = Vector2.UP
#			gs.rotation_degrees = anim_dir.x * 90 * -1
#		elif get_input_dir().y == 1:
#			if can_shoot_down:
#				animation_suffix += "2"
#				pc.shoot_dir = Vector2.DOWN
#				gs.rotation_degrees = anim_dir.x * 90
#			else:
#				animation_suffix += "3"
#
#	if "Back" in animation:
#		pc.shoot_dir.x *= -1
#		gs.scale.x *= -1
#
#
#	var next_animation = animation + animation_suffix
#	return next_animation
#
#
#func change_animation(next_animation, start_time = 0):
#	var blend_groups = [ #see if the string matches in new/old animations
#	"Stand.L",
#	"Stand.R",
#	"Run.L",
#	"Run.R",
#	"Backrun.L",
#	"Backrun.R",
#	"Climb",
#	]
#
#	if ap.current_animation:
#		for g in blend_groups:
#			if g in ap.current_animation and g in next_animation:
#				start_time = ap.current_animation_position
#
#	ap.play(next_animation)
#	ap.seek(start_time)
