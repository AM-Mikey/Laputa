extends Node

enum Layer {BACK, FRONT, BOTH}


onready var pc = get_tree().get_root().get_node("World/Recruit")
onready var mm = pc.get_node("MovementManager")
onready var ap = pc.get_node("AnimationPlayer")


func _physics_process(_delta):
	animate()


func animate():
	var next_animation: String = ""
	var start_time: float
	var run_anim_speed = max((abs(mm.velocity.x)/mm.speed.x) * 2, 0.1)
	var climb_anim_speed = mm.velocity.y / (mm.speed.y * 0.5)



	if mm.current_state == mm.states["ladder"]:
		ap.playback_speed = climb_anim_speed
		if get_input_dir().x != 0:
			next_animation = get_next_animation("Climb", get_input_dir(), true)
		else:
			next_animation = get_next_animation("Climb", pc.face_dir, true)


	else: #normal animation
		if pc.direction_lock == Vector2.ZERO:  #NOT DIRECTION LOCKED
		
			if pc.is_on_floor():
				
				if get_input_dir().x != 0:
					ap.playback_speed = run_anim_speed
					next_animation = get_next_animation("Run", get_input_dir(), pc.is_on_ssp)
				else:
					ap.playback_speed = 1
					match pc.inspecting:
						true: next_animation = get_next_animation("Reverseidle", pc.face_dir, true)
						false: next_animation = get_next_animation("Stand", pc.face_dir, pc.is_on_ssp)


			else: #arial
				ap.playback_speed = 0
				
				if get_input_dir() == Vector2.LEFT or get_input_dir() == Vector2.RIGHT:
					next_animation = get_next_animation("Arial", get_input_dir(), true)
				else:
					next_animation = get_next_animation("Arial", pc.face_dir, true)
				
				if mm.velocity.y < 0: 		#Rising
					start_time = 0
				elif mm.velocity.y == 0:	#Zenith
					start_time = 0.1
				else: 						#Falling
					start_time = 0.2



		elif pc.direction_lock == Vector2.LEFT: #DIRECTION LOCKED LEFT
			pc.face_dir = Vector2.LEFT
			
			if pc.is_on_floor():
				if get_input_dir().x == -1:
					ap.playback_speed = run_anim_speed
					next_animation = get_next_animation("Run", Vector2.LEFT, pc.is_on_ssp)
				elif get_input_dir().x == 1:
					ap.playback_speed = run_anim_speed
					next_animation = get_next_animation("Backrun", Vector2.RIGHT, pc.is_on_ssp)
				else:
					ap.playback_speed = 1
					match pc.inspecting:
						true: next_animation = get_next_animation("Reverseidle", pc.face_dir, true)
						false: next_animation = get_next_animation("Stand", pc.face_dir, pc.is_on_ssp)


			else: #arial
				ap.playback_speed = 0
				
				if get_input_dir().x == -1:
					next_animation = get_next_animation("Arial", Vector2.LEFT, true)
				elif get_input_dir().x == 1:
					next_animation = get_next_animation("Arial", Vector2.LEFT, true) #TODO backarial
				else:
					next_animation = get_next_animation("Arial", pc.face_dir, true)
				
				if mm.velocity.y < 0: 		#Rising
					start_time = 0
				elif mm.velocity.y == 0:	#Zenith
					start_time = 0.1
				else: 						#Falling
					start_time = 0.2


		elif pc.direction_lock == Vector2.RIGHT: #DIRECTION LOCKED RIGHT
			pc.face_dir = Vector2.RIGHT
			
			if pc.is_on_floor():
				if get_input_dir().x == -1:
					ap.playback_speed = run_anim_speed
					next_animation = get_next_animation("Backrun", Vector2.LEFT, pc.is_on_ssp)
				elif get_input_dir().x == 1:
					ap.playback_speed = run_anim_speed
					next_animation = get_next_animation("Run", Vector2.RIGHT, pc.is_on_ssp)
				else:
					ap.playback_speed = 1
					match pc.inspecting:
						true: next_animation = get_next_animation("Reverseidle", pc.face_dir, true)
						false: next_animation = get_next_animation("Stand", pc.face_dir, pc.is_on_ssp)


			else: #arial
				ap.playback_speed = 0
				
				if get_input_dir().x == -1:
					next_animation = get_next_animation("Arial", Vector2.RIGHT, true)
				elif get_input_dir().x == 1:
					next_animation = get_next_animation("Arial", Vector2.RIGHT, true) #TODO backarial
				else:
					next_animation = get_next_animation("Arial", pc.face_dir, true)
				
				if mm.velocity.y < 0: 		#Rising
					start_time = 0
				elif mm.velocity.y == 0:	#Zenith
					start_time = 0.1
				else: 						#Falling
					start_time = 0.2






	if (ap.current_animation != next_animation \
	or (ap.current_animation == next_animation and start_time)) and next_animation != "":
		change_animation(next_animation, start_time)



func get_input_dir() -> Vector2:
	if not pc.disabled:
		return Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	else:
		return Vector2(
			pc.move_dir.x if mm.current_state == mm.states["moveto"] else 0,
			0)



func get_next_animation(animation, anim_dir, can_shoot_down):
	var animation_suffix
	var gs = get_parent().get_node("GunSprite")
	
	pc.face_dir = anim_dir
	pc.shoot_dir = Vector2(anim_dir.x, 0)
	gs.rotation_degrees = 0
	
	if anim_dir.x == -1:
		animation_suffix = ".L"
		gs.scale.x = 1
	elif anim_dir.x == 1:
		animation_suffix = ".R"
		gs.scale.x = -1


	if not "Climb" in animation: #climbing doesnt look up or down so skip this section
		if get_input_dir().y == -1:
			animation_suffix += "1"
			pc.shoot_dir = Vector2.UP
			gs.rotation_degrees = anim_dir.x * 90 * -1
		elif get_input_dir().y == 1:
			if can_shoot_down:
				animation_suffix += "2"
				pc.shoot_dir = Vector2.DOWN
				gs.rotation_degrees = anim_dir.x * 90
			else:
				animation_suffix += "3"

	if "Back" in animation:
		pc.shoot_dir.x *= -1
		gs.scale.x *= -1
		
		
	var next_animation = animation + animation_suffix
	return next_animation


func change_animation(next_animation, start_time = 0):
	var old_animation = ap.current_animation
	var old_time = null
	if ap && ap.current_animation != "":
		old_time = ap.current_animation_position
	
	var _front = pc.get_node("Front")
	var _back = pc.get_node("Back")
	
	var blend_groups = [ #see if the string matches in new/old animations
		"Stand.L",
		"Stand.R",
		"Run.L",
		"Run.R",
		"Backrun.L",
		"Backrun.R",
		"Climb"
	]

	ap.play(next_animation)
	ap.seek(start_time)
	#blending
	if old_time:
		for g in blend_groups:
			if g in old_animation and g in next_animation:
				ap.seek(old_time)


