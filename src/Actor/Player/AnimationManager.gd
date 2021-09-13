extends Node

var run_anim_speed: float

onready var pc = get_tree().get_root().get_node("World/Recruit")
onready var ap = pc.get_node("AnimationPlayer")


func _physics_process(delta):
	run_anim_speed = max((abs(pc.velocity.x)/pc.speed.x) * 1.5, 0.1) #run_anim_speed = max((abs(velocity.x)/max_x_speed) * 1.5, 0.5)
	animate(pc.move_dir, pc.velocity)

func animate(move_dir, velocity):
	var texture
	var hframes
	var vframes

	var next_animation: String = ""
	
	if not pc.is_on_ladder:
		if pc.direction_lock == Vector2.ZERO:  #NOT DIRECTION LOCKED
		
			if pc.is_on_floor():
				
				if pc.is_on_ssp: #same as on normal ground but we can shoot down
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = 1
						texture = load("res://assets/Actor/Player/RecruitStand.png")
						next_animation = get_next_animation("Stand", pc.face_dir, true)
						
					elif get_input_dir().has(Vector2.LEFT) or get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = run_anim_speed
						texture = load("res://assets/Actor/Player/RecruitRun.png")
						if get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Run", Vector2.LEFT, true)
						if get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Run", Vector2.RIGHT, true)
							
					else:
						ap.playback_speed = 1
						texture = load("res://assets/Actor/Player/RecruitStand.png")
						next_animation = get_next_animation("Stand", pc.face_dir, false)
						
				else:
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = 1
						texture = load("res://assets/Actor/Player/RecruitStand.png")
						next_animation = get_next_animation("Stand", pc.face_dir, false)
						
					elif get_input_dir().has(Vector2.LEFT) or get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = run_anim_speed
						texture = load("res://assets/Actor/Player/RecruitRun.png")
						if get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Run", Vector2.LEFT, false)
						if get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Run", Vector2.RIGHT, false)
							
					else:
						ap.playback_speed = 1
						texture = load("res://assets/Actor/Player/RecruitStand.png")
						next_animation = get_next_animation("Stand", pc.face_dir, false)
				
				

			else: #airborne
				
				if pc.velocity.y < 0: #Rising
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						next_animation = get_next_animation("Rise", pc.face_dir, true)
					
					elif get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Rise", Vector2.LEFT, true)	
					elif get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Rise", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Rise", pc.face_dir, true)
				
				else: #Falling
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						next_animation = get_next_animation("Fall", pc.face_dir, true)
					
					elif get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Fall", Vector2.LEFT, true)
					elif get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Fall", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Fall", pc.face_dir, true)


		elif pc.direction_lock == Vector2.LEFT: #DIRECTION LOCKED LEFT
			pc.face_dir = Vector2.LEFT
			
			if pc.is_on_floor():
				
				if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", pc.face_dir, false)
				
				elif get_input_dir().has(Vector2.LEFT):
					ap.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					next_animation = get_next_animation("Run", Vector2.LEFT, false)
				
				elif get_input_dir().has(Vector2.RIGHT):
					ap.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitBackrun.png")
					next_animation = get_next_animation("Backrun", Vector2.RIGHT, false)
				
				else:
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", pc.face_dir, false)


			else: #airborne
				if velocity.y < 0: #Rising
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						next_animation = get_next_animation("Rise", pc.face_dir, true)
					
					elif get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Rise", Vector2.LEFT, true)	
					elif get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Rise", Vector2.LEFT, true)
					
					else:
						next_animation = get_next_animation("Rise", pc.face_dir, true)

				else: #Falling
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						next_animation = get_next_animation("Fall", pc.face_dir, true)
					
					elif get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Fall", Vector2.LEFT, true)
					elif get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Fall", Vector2.LEFT, true)
					
					else:
						next_animation = get_next_animation("Fall", pc.face_dir, true)


		elif pc.direction_lock == Vector2.RIGHT: #DIRECTION LOCKED RIGHT
			pc.face_dir = Vector2.RIGHT
			
			if pc.is_on_floor():
				
				if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", pc.face_dir, false)
				
				elif get_input_dir().has(Vector2.LEFT):
					ap.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitBackrun.png")
					next_animation = get_next_animation("Backrun", Vector2.LEFT, false)
				
				elif get_input_dir().has(Vector2.RIGHT):
					ap.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					next_animation = get_next_animation("Run", Vector2.RIGHT, false)
				
				else:
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", pc.face_dir, false)


			else: #airborne
				if velocity.y < 0: #Rising
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						next_animation = get_next_animation("Rise", pc.face_dir, true)
					
					elif get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Rise", Vector2.RIGHT, true)	
					elif get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Rise", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Rise", pc.face_dir, true)

				else: #Falling
					ap.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						next_animation = get_next_animation("Fall", pc.face_dir, true)
					
					elif get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Fall", Vector2.RIGHT, true)
					elif get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Fall", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Fall", pc.face_dir, true)


	else: #is on ladder
		ap.playback_speed = 1 #reset ap to normal speed
		texture = load("res://assets/Actor/Player/RecruitClimb.png")
		
		if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
			next_animation = get_next_animation("Climb", pc.face_dir, true)
		
		elif get_input_dir().has(Vector2.LEFT):
			next_animation = get_next_animation("Climb", Vector2.LEFT, true)	
		elif get_input_dir().has(Vector2.RIGHT):
			next_animation = get_next_animation("Climb", Vector2.RIGHT, true)
		
		else:
			next_animation = get_next_animation("Climb", pc.face_dir, true)



	if ap.current_animation != next_animation and next_animation != "":
		change_animation(next_animation, texture)


func get_input_dir() -> Array:
	var dir_list = []
	
	if not pc.disabled:
		if Input.is_action_pressed("move_left"): 
			dir_list.append(Vector2.LEFT)
		if Input.is_action_pressed("move_right"):
			dir_list.append(Vector2.RIGHT)
		if Input.is_action_pressed("look_up"):
			dir_list.append(Vector2.UP)
		if Input.is_action_pressed("look_down"):
			dir_list.append(Vector2.DOWN)
	else: dir_list = [Vector2.ZERO]
	
	return dir_list


func get_next_animation(animation, anim_dir, can_shoot_down):
	var animation_suffix
	
	if anim_dir == Vector2.LEFT:
		pc.face_dir = Vector2.LEFT
		
		if get_input_dir().has(Vector2.UP) and get_input_dir().has(Vector2.DOWN):
			animation_suffix = "Left"
			pc.shoot_dir = Vector2.LEFT
			
		elif get_input_dir().has(Vector2.UP):
			animation_suffix = "LeftLookUp"
			pc.shoot_dir = Vector2.UP
			
		elif get_input_dir().has(Vector2.DOWN):
			animation_suffix = "LeftLookDown"
			if can_shoot_down:
				pc.shoot_dir = Vector2.DOWN
			else:
				pc.shoot_dir = Vector2.LEFT
		
		else:
			animation_suffix = "Left"
			pc.shoot_dir = Vector2.LEFT
			
	
	if anim_dir == Vector2.RIGHT:
		pc.face_dir = Vector2.RIGHT

		if get_input_dir().has(Vector2.UP) and get_input_dir().has(Vector2.DOWN):
			animation_suffix = "Right"
			pc.shoot_dir = Vector2.RIGHT

		elif get_input_dir().has(Vector2.UP):
			animation_suffix = "RightLookUp"
			pc.shoot_dir = Vector2.UP
			
		elif get_input_dir().has(Vector2.DOWN):
			animation_suffix = "RightLookDown"
			if can_shoot_down:
				pc.shoot_dir = Vector2.DOWN
			else:
				pc.shoot_dir = Vector2.RIGHT
		
		else:
			animation_suffix = "Right"
			pc.shoot_dir = Vector2.RIGHT
		
		
	var backwards = "Back" in animation
	if backwards:
		pc.shoot_dir.x *= -1
		
	var next_animation = animation + animation_suffix
	return next_animation


func change_animation(next_animation, texture):
	var old_animation = ap.current_animation
	var old_time = ap.current_animation_position
	
	var front = pc.get_node("Front")
	var back = pc.get_node("Back")
	
	front.texture = texture
	front.hframes = texture.get_width() /32
	front.vframes = texture.get_height() /32
	back.texture = texture
	back.hframes = texture.get_width() /32
	back.vframes = texture.get_height() /32
	
	var animation_groups = {
		"StandLeft": 1,
		"StandLeftLookUp": 1,
		"StandLeftLookDown": 1,
		"StandRight": 2,
		"StandRightLookUp": 2,
		"StandRightLookDown": 2,
		"RunLeft": 3,
		"RunLeftLookUp": 3,
		"RunLeftLookDown": 3,
		"RunRight": 4,
		"RunRightLookUp": 4,
		"RunRightLookDown": 4,
		"BackrunLeft": 5,
		"BarckrunLeftLookUp": 5,
		"BackrunLeftLookDown": 5,
		"BackrunRight": 6,
		"BarckrunRightLookUp": 6,
		"BackrunRightLookDown": 6
	}
	
	ap.play(next_animation)
	
	#blending
	if animation_groups.has(old_animation) and animation_groups.has(next_animation):
		if animation_groups[old_animation] == animation_groups[next_animation]:
			ap.seek(old_time)


