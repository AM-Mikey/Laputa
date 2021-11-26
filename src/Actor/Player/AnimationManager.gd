extends Node

enum Layer {BACK, FRONT, BOTH}

var tx_stand = preload("res://assets/Actor/Player/Stand.png")
var tx_run = preload("res://assets/Actor/Player/Run.png")
var tx_backrun = preload("res://assets/Actor/Player/RecruitBackrun.png")
var tx_rise = preload("res://assets/Actor/Player/Rise.png")
var tx_fall = preload("res://assets/Actor/Player/RecruitFall.png")
var tx_climb = preload("res://assets/Actor/Player/RecruitClimb.png")

var run_anim_speed: float

onready var pc = get_tree().get_root().get_node("World/Recruit")
onready var ap = pc.get_node("AnimationPlayer")


func _physics_process(delta):
	run_anim_speed = max((abs(pc.velocity.x)/pc.speed.x) * 2, 0.1) #run_anim_speed = max((abs(velocity.x)/max_x_speed) * 1.5, 0.5) #was 1.5 rev it up to 2
	animate(pc.move_dir, pc.velocity)

func animate(move_dir, velocity):
	var texture
	var hframes
	var vframes

	var next_animation: String = ""
	
	if pc.is_inspecting:
		ap.playback_speed = 1
		texture = load("res://assets/Actor/Player/Reverseidle.png") #TODO animation should remove this
		next_animation = get_next_animation("Reverseidle", pc.face_dir, true)
		
	elif not pc.is_on_ladder:
		if pc.direction_lock == Vector2.ZERO:  #NOT DIRECTION LOCKED
		
			if pc.is_on_floor():
				
				if pc.is_on_ssp: #same as on normal ground but we can shoot down
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = 1
						texture = tx_stand
						next_animation = get_next_animation("Stand", pc.face_dir, true)
						
					elif get_input_dir().has(Vector2.LEFT) or get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = run_anim_speed
						texture = tx_run
						if get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Run", Vector2.LEFT, true)
						if get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Run", Vector2.RIGHT, true)
							
					else:
						ap.playback_speed = 1
						texture = tx_stand
						next_animation = get_next_animation("Stand", pc.face_dir, true)
						
				else:
					if get_input_dir().has(Vector2.LEFT) and get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = 1
						texture = tx_stand
						next_animation = get_next_animation("Stand", pc.face_dir, false)
						
					elif get_input_dir().has(Vector2.LEFT) or get_input_dir().has(Vector2.RIGHT):
						ap.playback_speed = run_anim_speed
						texture = tx_run
						if get_input_dir().has(Vector2.LEFT):
							next_animation = get_next_animation("Run", Vector2.LEFT, false)
						if get_input_dir().has(Vector2.RIGHT):
							next_animation = get_next_animation("Run", Vector2.RIGHT, false)
							
					else:
						ap.playback_speed = 1
						texture = tx_stand
						next_animation = get_next_animation("Stand", pc.face_dir, false)
				
				

			else: #airborne
				
				if pc.velocity.y < 0: #Rising
					ap.playback_speed = 1
					texture = tx_rise
					
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
					texture = tx_fall
					
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
					texture = tx_stand
					next_animation = get_next_animation("Stand", pc.face_dir, false)
				
				elif get_input_dir().has(Vector2.LEFT):
					ap.playback_speed = run_anim_speed
					texture = tx_run
					next_animation = get_next_animation("Run", Vector2.LEFT, false)
				
				elif get_input_dir().has(Vector2.RIGHT):
					ap.playback_speed = run_anim_speed
					texture = tx_backrun
					next_animation = get_next_animation("Backrun", Vector2.RIGHT, false)
				
				else:
					ap.playback_speed = 1
					texture = tx_stand
					next_animation = get_next_animation("Stand", pc.face_dir, false)


			else: #airborne
				if velocity.y < 0: #Rising
					ap.playback_speed = 1
					texture = tx_rise
					
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
					texture = tx_fall
					
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
					texture = tx_stand
					next_animation = get_next_animation("Stand", pc.face_dir, false)
				
				elif get_input_dir().has(Vector2.LEFT):
					ap.playback_speed = run_anim_speed
					texture = tx_backrun
					next_animation = get_next_animation("Backrun", Vector2.LEFT, false)
				
				elif get_input_dir().has(Vector2.RIGHT):
					ap.playback_speed = run_anim_speed
					texture = tx_run
					next_animation = get_next_animation("Run", Vector2.RIGHT, false)
				
				else:
					ap.playback_speed = 1
					texture = tx_stand
					next_animation = get_next_animation("Stand", pc.face_dir, false)


			else: #airborne
				if velocity.y < 0: #Rising
					ap.playback_speed = 1
					texture = tx_rise
					
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
					texture = tx_fall
					
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
		texture = tx_climb
		
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


func setup_sprites(texture: StreamTexture):
	print("setting up")
	var front = pc.get_node("Front")
	var back = pc.get_node("Back")
	

	front.texture = texture
	front.hframes = texture.get_width() /32
	front.vframes = texture.get_height() /32
	back.texture = texture
	back.hframes = texture.get_width() /32
	back.vframes = texture.get_height() /32


func get_next_animation(animation, anim_dir, can_shoot_down):
	var animation_suffix
	
	var ws = get_parent().get_node("WeaponSprite")
	
	if anim_dir == Vector2.LEFT:
		pc.face_dir = Vector2.LEFT
		ws.scale.x = 1
		
		if get_input_dir().has(Vector2.UP) and get_input_dir().has(Vector2.DOWN):
			animation_suffix = ".L"
			pc.shoot_dir = Vector2.LEFT
			ws.rotation_degrees = 0
			
		elif get_input_dir().has(Vector2.UP):
			animation_suffix = ".L1"
			pc.shoot_dir = Vector2.UP
			ws.rotation_degrees = 90
			
		elif get_input_dir().has(Vector2.DOWN):
			if can_shoot_down:
				animation_suffix = ".L2"
				pc.shoot_dir = Vector2.DOWN
				ws.rotation_degrees = -90
			else:
				animation_suffix = ".L3"
				pc.shoot_dir = Vector2.LEFT
				ws.rotation_degrees = 0
		
		else:
			animation_suffix = ".L"
			pc.shoot_dir = Vector2.LEFT
			ws.rotation_degrees = 0
			
	
	if anim_dir == Vector2.RIGHT:
		pc.face_dir = Vector2.RIGHT
		ws.scale.x = -1

		if get_input_dir().has(Vector2.UP) and get_input_dir().has(Vector2.DOWN):
			animation_suffix = ".R"
			pc.shoot_dir = Vector2.RIGHT
			ws.rotation_degrees = 0

		elif get_input_dir().has(Vector2.UP):
			animation_suffix = ".R1"
			pc.shoot_dir = Vector2.UP
			ws.rotation_degrees = -90
			
		elif get_input_dir().has(Vector2.DOWN):
			if can_shoot_down:
				animation_suffix = ".R2"
				pc.shoot_dir = Vector2.DOWN
				ws.rotation_degrees = 90
			else:
				animation_suffix = ".R3"
				pc.shoot_dir = Vector2.RIGHT
				ws.rotation_degrees = 0
		
		else:
			animation_suffix = ".R"
			pc.shoot_dir = Vector2.RIGHT
			ws.rotation_degrees = 0
		
		
	var backwards = "Back" in animation
	if backwards:
		pc.shoot_dir.x *= -1
		ws.scale.x *= -1
		
	var next_animation = animation + animation_suffix
	return next_animation


func change_animation(next_animation, texture):
	var old_animation = ap.current_animation
	var old_time = ap.current_animation_position
	
	var front = pc.get_node("Front")
	var back = pc.get_node("Back")
	
	var animation_layers = {
		"RunLeft": Layer.BACK,
		"RunLeftLookUp": Layer.BACK,
		"RunLeftLookDown": Layer.BACK,
		"RunRight": Layer.BOTH,
		"RunRightLookUp": Layer.BOTH,
		"RunRightLookDown": Layer.BOTH
	}

	front.texture = texture
	front.hframes = texture.get_width() /32
	front.vframes = texture.get_height() /32
	back.texture = texture
	back.hframes = texture.get_width() /32
	back.vframes = texture.get_height() /32
	
	
	
	if animation_layers.has(next_animation):
		if animation_layers[next_animation] == Layer.FRONT:
			back.texture = null
		elif animation_layers[next_animation] == Layer.BACK:
			front.texture = null
	
	
	var animation_groups = { #only add if it needs to blend
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


