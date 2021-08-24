extends Player

const BLACKBAR = preload("res://src/Utility/BlackBar.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")


export var max_x_speed = 90 #was 82.5 for a max gap of 7 (barely)
var half_max_x_speed = max_x_speed/2
export var jump_speed = 180 #was 195 for 4 blocks
#export var normal_jump_speed = 195
#export var long_jump_speed = 150
var movement_profile = "sigma"

export var minimum_jump_time = 0.0000000001 #was 0.1
export var minimum_direction_time = 1.0 #was 0.5  #scrapped idea where cave story forces you to jump a certain x distance when going max speed before jumping
var jump_starting_move_dir_x: int

var jump_type: String

export var min_xvelocity = 0.001

var horizontal_focus = Vector2.LEFT
var homing_camera = false
var panning_up = false
var panning_down = false

var direction_lock = Vector2.ZERO
var starting_direction #for acceleration
var bonk_distance = 4


export var knockback_speed = Vector2(80, 100)
var knockbackvelocity = Vector2.ZERO


var run_anim_speed: float

onready var world = get_tree().get_root().get_node("World")

func _ready():
	acceleration = 2.5 #was 5
	ground_cof = 0.1 #was 0.2
	air_cof = 0.00 # was 0.05
	
	$BonkTimeout.start(0.4)

func _physics_process(delta):
	#print("Velocity: ", velocity)
	if disabled != true:
		if colliding == true: #skip this entire thing if we're in debug mode
			
			var is_jump_interrupted = false
			if $MinimumJumpTimer.time_left == 0 and velocity.y < 0.0:
				if not Input.is_action_pressed("jump"):
					is_jump_interrupted = true
				
				
			var move_dir = get_move_dir()
			var bullet_pos = $BulletOrigin.global_position
			var effect_pos = $WeaponSprite.position
			
			if is_on_ceiling():
				if $BonkTimeout.time_left == 0:
					$BonkTimeout.start(0.4)
					var collision = get_slide_collision(0)
					print("collision normal:", collision.normal)
					var bonk = load("res://src/Effect/BonkParticle.tscn").instance()
					var bonk_position = position
					bonk_position.y -= 16
					bonk.position = bonk_position
					bonk.normal = collision.normal
					bonk.type = "bonk"
					get_tree().get_root().get_node("World/Front").add_child(bonk)
				
			
			if is_on_floor():
				jump_type = ""
#				jump_speed = normal_jump_speed
					
				if not knockback and not is_on_ladder:
					snap_vector = SNAP_DIRECTION * SNAP_LENGTH
				else: 
					snap_vector = Vector2.ZERO
				
				if $ForgivenessTimer.time_left == 0: #just landed
					if $BonkTimeout.time_left == 0:
						$BonkTimeout.start(0.4)
						var collision = get_slide_collision(get_slide_count() - 1)
						print("collision normal:", collision.normal)
						var bonk = load("res://src/Effect/BonkParticle.tscn").instance()
						bonk.position = position
						bonk.normal = collision.normal
						bonk.type = "land"
						get_tree().get_root().get_node("World/Front").add_child(bonk)
			
				if is_on_ladder:
					if Input.is_action_pressed("look_down"):
						is_on_ladder = false


				$ForgivenessTimer.start(forgiveness_time) #start forgiveness timer on any frame they're on the ground




			
			
			
			if Input.is_action_just_pressed("jump") and $ForgivenessTimer.time_left > 0 or Input.is_action_just_pressed("jump") and is_on_floor():
				$MinimumJumpTimer.start(minimum_jump_time)
				if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
					if abs(velocity.x) > 82: #since 82.5 is max x velocity, only count as a running jump then   ##Running JUMP CHECKING HERE
						jump_type = "running_jump"
#						jump_speed = long_jump_speed
						jump_starting_move_dir_x = move_dir.x
						$MinimumDirectionTimer.start(minimum_direction_time)
				snap_vector = Vector2.ZERO
				
#				if get_floorvelocity().y < 0: #borrowed this code to prevent sticking
#					position.y += get_floorvelocity().y * get_physics_process_delta_time() - gravity * get_physics_process_delta_time() - 1
				
				$JumpSound.play()
		
			
			if Input.is_action_just_pressed("look_down") and can_fall_through == true and is_on_floor():
				position.y += 8
				
			if knockback:
				if knockbackvelocity == Vector2.ZERO:
					knockbackvelocity = Vector2(knockback_speed.x * knockback_direction.x, knockback_speed.y * -1)
					velocity.y = knockbackvelocity.y #set knockback y to this ONCE
				
				velocity.x += knockbackvelocity.x
				#print("velocity: ", velocity)
				#print("knockback velocity: ", knockbackvelocity)
				knockbackvelocity.x /= 2
				
				if abs(knockbackvelocity.x) < 1:
					knockbackvelocity = Vector2.ZERO
					knockback = false

			velocity = get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted)
			var new_velocity = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, true)
			
			if is_on_wall():
				new_velocity.y = max(velocity.y, new_velocity.y)
			
			velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
			
			run_anim_speed = max((abs(velocity.x)/max_x_speed) * 1.5, 0.1) #run_anim_speed = max((abs(velocity.x)/max_x_speed) * 1.5, 0.5)
			#print(run_anim_speed)
			animate(move_dir, velocity)
			
			if Input.is_action_pressed("fire_manual"): #holding
				$WeaponManager.manual_fire(bullet_pos, effect_pos, shoot_dir)
			if Input.is_action_pressed("fire_automatic"): #holding
				$WeaponManager.automatic_fire(bullet_pos, effect_pos, shoot_dir)
			if Input.is_action_just_pressed("fire_automatic"): #only on first pressed
				direction_lock = face_dir
			if Input.is_action_just_released("fire_manual"):
				$WeaponManager.release_fire()
			if Input.is_action_just_released("fire_automatic"): 
				$WeaponManager.release_fire()
				direction_lock = Vector2.ZERO
			
			if face_dir == Vector2.LEFT and horizontal_focus == Vector2.RIGHT:
				horizontal_focus = Vector2.LEFT
				pan_camera_horizontal(face_dir, velocity)
			if face_dir == Vector2.RIGHT and horizontal_focus == Vector2.LEFT:
				horizontal_focus = Vector2.RIGHT
				pan_camera_horizontal(face_dir, velocity)
			
			if $Camera2D/TweenHorizontal.is_active():
				$Camera2D/TweenHorizontal.playback_speed = max(abs(velocity.x)/max_x_speed, 0.5) #second number is minimum camera speed ##thanks me!
			
#			if Input.is_action_pressed("look_up") and Input.is_action_pressed("look_down"):
#				print("hi")
#				panning_up = false
#				panning_down = false
#				home_camera_vertical()
#
			if Input.is_action_just_pressed("look_up"):
				if panning_down:
					panning_up = false
					home_camera_vertical()
				elif not panning_up:
					panning_up = true
					pan_camera_vertical(-1)

			if Input.is_action_just_pressed("look_down"):
				if panning_up:
					panning_down = false
					home_camera_vertical()
				elif not panning_down:
					panning_down = true
					pan_camera_vertical(1)

			if Input.is_action_just_released("look_up"):
				if Input.is_action_pressed("look_down"):
					panning_down = true
					pan_camera_vertical(1)
				else:
					panning_up = false
					home_camera_vertical()
			
			if Input.is_action_just_released("look_down"):
				if Input.is_action_pressed("look_up"):
					panning_up = true
					pan_camera_vertical(-1)
				else:
					panning_down = false
					home_camera_vertical()

			debug_print(move_dir, face_dir)
		
		else: #debug mode is on
			var move_dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
			velocity = Vector2(
			debug_speed * move_dir.x,
			debug_speed * move_dir.y)
			velocity = move_and_slide(velocity, FLOOR_NORMAL, true)

	else: #we are curently disabled
		pass

func get_move_dir() -> Vector2:
	if is_on_ladder:
		return Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
			)
	else:
		return Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			
			-1.0 if Input.is_action_just_pressed("jump") and $ForgivenessTimer.time_left > 0 or Input.is_action_just_pressed("jump") and is_on_floor() 
			else 0.0)

func get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted) -> Vector2:
	var out = velocity
	
	var friction = false
	
	if is_on_ladder:
		out.y = move_dir.y * jump_speed/2

		out.x = 0
		if Input.is_action_just_pressed("jump"):
			is_on_ladder = false
			out.y = jump_speed * -1.0
	
	elif is_in_water:
		out.y += (gravity/2) * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = (jump_speed * 0.75) * move_dir.y
		if is_jump_interrupted:
			out.y += (gravity/2) * get_physics_process_delta_time()
		
		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, (max_x_speed/2))
			out.x *= move_dir.x
		else:
			friction = true

	elif jump_type == "running_jump":
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = jump_speed * move_dir.y
		if is_jump_interrupted:
			out.y += gravity * get_physics_process_delta_time()
		
		if move_dir.x == jump_starting_move_dir_x *-1: #if we turn around, cancel minimumdirectiontimer
			$MinimumDirectionTimer.stop()
		
		if not $MinimumDirectionTimer.is_stopped(): #still doing minimum x movement in jump #
			#print("still doing minimum x movement")
			out.x = max_x_speed
			out.x *= jump_starting_move_dir_x
		
		
		elif move_dir.x != 0: #try this as an "if" instead, if it's not working
			if move_dir.x != jump_starting_move_dir_x:
				out.x = min(abs(out.x) + acceleration, half_max_x_speed)
				out.x *= move_dir.x
				#$MinimumDirectionTimer.start(0)
			else:
				out.x = min(abs(out.x) + acceleration, max_x_speed)
				out.x *= move_dir.x
		else:
			friction = true
		
	
	else:
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = jump_speed * move_dir.y
		if is_jump_interrupted:
			out.y += gravity * get_physics_process_delta_time()

		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, max_x_speed)
			out.x *= move_dir.x
		else:
			friction = true



	if is_on_floor():
		if friction == true:
			out.x = lerp(out.x, 0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0, air_cof)


	if abs(out.x) < min_xvelocity:
		out.x = 0
	#print(out)
	return out


func get_input_dir() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_up") - Input.get_action_strength("look_down"))
	

func animate(move_dir, velocity):
	var player = $AnimationPlayer
	var camera = $Camera2D
	

	
	var texture
	var hframes
	var vframes
	
	var input_dir = get_input_dir()

	
	#var minimumvelocity = 1 #for the difference between moving and standing

	var next_animation: String = ""
	
	if not is_on_ladder:
		if direction_lock == Vector2.ZERO:  #NOT DIRECTION LOCKED
		
			if is_on_floor():
				
				if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", face_dir, false)
					
				elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
					player.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					if Input.is_action_pressed("move_left"):
						next_animation = get_next_animation("Run", Vector2.LEFT, false)
					if Input.is_action_pressed("move_right"):
						next_animation = get_next_animation("Run", Vector2.RIGHT, false)
						
				else:
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", face_dir, false)


			else: #airborne
				
				if velocity.y < 0: #Rising
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
						next_animation = get_next_animation("Rise", face_dir, true)
					
					elif Input.is_action_pressed("move_left"):
							next_animation = get_next_animation("Rise", Vector2.LEFT, true)	
					elif Input.is_action_pressed("move_right"):
							next_animation = get_next_animation("Rise", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Rise", face_dir, true)
				
				else: #Falling
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
						next_animation = get_next_animation("Fall", face_dir, true)
					
					elif Input.is_action_pressed("move_left"):
							next_animation = get_next_animation("Fall", Vector2.LEFT, true)
					elif Input.is_action_pressed("move_right"):
							next_animation = get_next_animation("Fall", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Fall", face_dir, true)


		elif direction_lock == Vector2.LEFT: #DIRECTION LOCKED LEFT
			face_dir = Vector2.LEFT
			
			if is_on_floor():
				
				if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", face_dir, false)
				
				elif Input.is_action_pressed("move_left"):
					player.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					next_animation = get_next_animation("Run", Vector2.LEFT, false)
				
				elif Input.is_action_pressed("move_right"):
					player.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitBackrun.png")
					next_animation = get_next_animation("Backrun", Vector2.RIGHT, false)
				
				else:
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", face_dir, false)


			else: #airborne
				if velocity.y < 0: #Rising
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
						next_animation = get_next_animation("Rise", face_dir, true)
					
					elif Input.is_action_pressed("move_left"):
							next_animation = get_next_animation("Rise", Vector2.LEFT, true)	
					elif Input.is_action_pressed("move_right"):
							next_animation = get_next_animation("Rise", Vector2.LEFT, true)
					
					else:
						next_animation = get_next_animation("Rise", face_dir, true)

				else: #Falling
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
						next_animation = get_next_animation("Fall", face_dir, true)
					
					elif Input.is_action_pressed("move_left"):
							next_animation = get_next_animation("Fall", Vector2.LEFT, true)
					elif Input.is_action_pressed("move_right"):
							next_animation = get_next_animation("Fall", Vector2.LEFT, true)
					
					else:
						next_animation = get_next_animation("Fall", face_dir, true)


		elif direction_lock == Vector2.RIGHT: #DIRECTION LOCKED RIGHT
			face_dir = Vector2.RIGHT
			
			if is_on_floor():
				
				if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", face_dir, false)
				
				elif Input.is_action_pressed("move_left"):
					player.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitBackrun.png")
					next_animation = get_next_animation("Backrun", Vector2.LEFT, false)
				
				elif Input.is_action_pressed("move_right"):
					player.playback_speed = run_anim_speed
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					next_animation = get_next_animation("Run", Vector2.RIGHT, false)
				
				else:
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					next_animation = get_next_animation("Stand", face_dir, false)


			else: #airborne
				if velocity.y < 0: #Rising
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
						next_animation = get_next_animation("Rise", face_dir, true)
					
					elif Input.is_action_pressed("move_left"):
							next_animation = get_next_animation("Rise", Vector2.RIGHT, true)	
					elif Input.is_action_pressed("move_right"):
							next_animation = get_next_animation("Rise", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Rise", face_dir, true)

				else: #Falling
					player.playback_speed = 1
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
						next_animation = get_next_animation("Fall", face_dir, true)
					
					elif Input.is_action_pressed("move_left"):
							next_animation = get_next_animation("Fall", Vector2.RIGHT, true)
					elif Input.is_action_pressed("move_right"):
							next_animation = get_next_animation("Fall", Vector2.RIGHT, true)
					
					else:
						next_animation = get_next_animation("Fall", face_dir, true)


	else: #is on ladder
		player.playback_speed = 1 #reset player to normal speed
		texture = load("res://assets/Actor/Player/RecruitClimb.png")
		
		if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
			next_animation = get_next_animation("Climb", face_dir, true)
		
		elif Input.is_action_pressed("move_left"):
			next_animation = get_next_animation("Climb", Vector2.LEFT, true)	
		elif Input.is_action_pressed("move_right"):
			next_animation = get_next_animation("Climb", Vector2.RIGHT, true)
		
		else:
			next_animation = get_next_animation("Climb", face_dir, true)




	if not player.current_animation == next_animation:
		if next_animation != "":
			change_animation(next_animation, texture)

func get_next_animation(animation, anim_dir, can_shoot_down):
	var animation_suffix
	
	if anim_dir == Vector2.LEFT:
		face_dir = Vector2.LEFT
		
		if Input.is_action_pressed("look_up") and Input.is_action_pressed("look_down"):
			animation_suffix = "Left"
			shoot_dir = Vector2.LEFT
			
		elif Input.is_action_pressed("look_up"):
			animation_suffix = "LeftLookUp"
			shoot_dir = Vector2.UP
			
		elif Input.is_action_pressed("look_down"):
			animation_suffix = "LeftLookDown"
			if can_shoot_down:
				shoot_dir = Vector2.DOWN
			else:
				shoot_dir = Vector2.LEFT
		
		else:
			animation_suffix = "Left"
			shoot_dir = Vector2.LEFT
			
	
	if anim_dir == Vector2.RIGHT:
		face_dir = Vector2.RIGHT

		if Input.is_action_pressed("look_up") and Input.is_action_pressed("look_down"):
			animation_suffix = "Right"
			shoot_dir = Vector2.RIGHT

		elif Input.is_action_pressed("look_up"):
			animation_suffix = "RightLookUp"
			shoot_dir = Vector2.UP
			
		elif Input.is_action_pressed("look_down"):
			animation_suffix = "RightLookDown"
			if can_shoot_down:
				shoot_dir = Vector2.DOWN
			else:
				shoot_dir = Vector2.RIGHT
		
		else:
			animation_suffix = "Right"
			shoot_dir = Vector2.RIGHT
		
		
	var back = "Back" in animation
	if back:
		shoot_dir.x *= -1
		
	var next_animation = animation + animation_suffix
	return next_animation


func change_animation(next_animation, texture):
	var player = $AnimationPlayer
	var old_animation = $AnimationPlayer.current_animation
	var old_time = $AnimationPlayer.current_animation_position
	
	var front = $Front
	var back = $Back
	
	front.texture = texture
	front.hframes = texture.get_width()  /32
	front.vframes = texture.get_height() /32
	back.texture = texture
	back.hframes = texture.get_width()  /32
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
	
	player.play(next_animation)
	if animation_groups.has(old_animation) and animation_groups.has(next_animation):
		if animation_groups[old_animation] == animation_groups[next_animation]:
			$AnimationPlayer.seek(old_time)

#func _on_BonkDetector_body_entered(body, direction):
#	if not is_on_floor():
#		global_position += (direction * -1) * Vector2(bonk_distance, 0)

func _on_limit_camera(left, right, top, bottom):
	var camera = $Camera2D
	
	var bars = get_tree().get_nodes_in_group("BlackBars")
	for b in bars:
		b.free()
	
	
	if  OS.get_window_size().x > (right - left) * world.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = ((OS.get_window_size().x / world.resolution_scale) - (right - left))/2
		
		camera.limit_left = left - extra_margin
		camera.limit_right = right + extra_margin
		
		var left_pillar = BLACKBAR.instance()
		left_pillar.name = "BlackBarLeft"
		left_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		world.get_node("UILayer").add_child(left_pillar)
		world.get_node("UILayer").move_child(left_pillar, 0)
		
		var right_pillar = BLACKBAR.instance()
		right_pillar.name = "BlackBarRight"
		right_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		right_pillar.rect_position = Vector2((right - left) + extra_margin, 0)
		world.get_node("UILayer").add_child(right_pillar)
		world.get_node("UILayer").move_child(right_pillar, 0)
		
	else:
		camera.limit_left = left
		camera.limit_right = right
#		world.get_node("UILayer/HUD").rect_position.x = 0
	
	if OS.get_window_size().y > (bottom - top) * world.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (OS.get_window_size().y - (bottom - top))/2
		camera.limit_top = top - extra_margin
		camera.limit_bottom = bottom  + extra_margin
		
		var top_pillar = BLACKBAR.instance()
		top_pillar.name = "BlackBarTop"
		top_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		world.get_node("UILayer").add_child(top_pillar)
		world.get_node("UILayer").move_child(top_pillar, 0)
		
		var bottom_pillar = BLACKBAR.instance()
		bottom_pillar.name = "BlackBarRight"
		bottom_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		bottom_pillar.rect_position = Vector2(0, (bottom - top) + extra_margin)
		world.get_node("UILayer").add_child(bottom_pillar)
		world.get_node("UILayer").move_child(bottom_pillar, 0)
	
	else:
		camera.limit_top = top
		camera.limit_bottom = bottom
#		world.get_node("UILayer/HUD").rect_position.y = 0

func pan_camera_vertical(direction):
	var camera = $Camera2D
	var tween = $Camera2D/TweenVertical
	
	var camera_pan_distance = 2 / world.resolution_scale
	var camera_pan_time = 1.5
	var camera_pan_delay = 0
	
	yield(get_tree().create_timer(camera_pan_delay), "timeout")
	
	if tween.is_active():
		tween.stop_all()
	#	homing_camera = false
	tween.interpolate_property(camera, "offset_v", camera.offset_v, direction * camera_pan_distance, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

func home_camera_vertical():
	var camera = $Camera2D
	var tween = $Camera2D/TweenVertical
	
	var camera_pan_time = 1.5
	
	if tween.is_active():
		tween.stop_all()
	tween.interpolate_property(camera, "offset_v", camera.offset_v, 0, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")

func pan_camera_horizontal(direction, velocity):
	var camera = $Camera2D
	var tween = $Camera2D/TweenHorizontal
	
	var camera_pan_distance = 2.0 / world.resolution_scale
	var camera_pan_time = 1.5
	var camera_pan_delay = 0
	
	yield(get_tree().create_timer(camera_pan_delay), "timeout")
	
	if tween.is_active():
		tween.stop_all()
	#	homing_camera = false
	tween.interpolate_property(camera, "offset_h", camera.offset_h, direction.x * camera_pan_distance, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()

func home_camera_horizontal():
	var camera = $Camera2D
	var tween = $Camera2D/TweenHorizontal
	
	var camera_pan_time = 1.5
	
	if tween.is_active():
		tween.stop_all()
	tween.interpolate_property(camera, "offset_h", camera.offset_h, 0, camera_pan_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
	yield(tween, "tween_completed")

func _input(event):
	if event.is_action_pressed("movement_profile"):
		if movement_profile == "sigma":
			movement_profile = "mu"
			
			max_x_speed = 82.5
			jump_speed = 180
			
			acceleration = 5
			ground_cof = 0.2
			air_cof = 0.05
			
		elif movement_profile == "mu":
			movement_profile = "chi"
			
			max_x_speed = 90
			jump_speed = 180
			
			acceleration = 2.5
			ground_cof = 0.1
			air_cof = 0.05
		
		elif movement_profile == "chi":
			movement_profile = "sigma"
			
			max_x_speed = 90
			jump_speed = 180
			
			acceleration = 2.5
			ground_cof = 0.1
			air_cof = 0.00
		
		
		yield(get_tree(), "idle_frame")
		var popup = POPUP.instance()
		popup.text = "movement profile: " + movement_profile
		world.get_node("UILayer").add_child(popup)







