extends Player

const BLACKBAR = preload("res://src/Utility/BlackBar.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")

export var max_x_speed = 90 #was 82.5 for a max gap of 7 (barely)
var half_max_x_speed = max_x_speed/2
export var jump_speed = 180 #was 195 for 4 blocks
#export var normal_jump_speed = 195
#export var long_jump_speed = 150
var movement_profile = "chi"

export var minimum_jump_time = 0.1
export var minimum_direction_time = 1.0 #was 0.5  #scrapped idea where cave story forces you to jump a certain x distance when going max speed before jumping
var jump_starting_move_dir_x: int

var jump_type: String

export var min_x_velocity = 0.001

var horizontal_focus = Vector2.LEFT
var homing_camera = false
var panning_up = false
var panning_down = false

var direction_lock = Vector2.ZERO
var starting_direction #for acceleration
var bonk_distance = 4


export var knockback_speed = Vector2(80, 100)
var knockback_velocity = Vector2.ZERO


var run_anim_speed: float

onready var world = get_tree().get_root().get_node("World")

func _ready():
	acceleration = 2.5 #was 5
	ground_cof = 0.1 #was 0.2
	air_cof = 0.05 # was 0.05

func _physics_process(delta):
	#print("Velocity: ", _velocity)
	if disabled != true:
		if colliding == true: #skip this entire thing if we're in debug mode
			
			var is_jump_interrupted = false
			if $MinimumJumpTimer.time_left == 0 and _velocity.y < 0.0:
				if not Input.is_action_pressed("jump"):
					is_jump_interrupted = true
				
				
			var move_dir = get_move_dir()
			var bullet_pos = $BulletOrigin.global_position
			var effect_pos = $WeaponSprite.position
			
			if is_on_ceiling():
				#if bonk_dir == Vector2.ZERO:
				$BonkSound.play()
			
			if is_on_floor(): #start forgiveness timer on any frame they're on
				jump_type = ""
#				jump_speed = normal_jump_speed
				if is_on_ladder == true:
					is_on_ladder = false
					if face_dir.x < 0: #Left
						$AnimationPlayer.play("StandLeft")
					elif face_dir.x < 0: #Left
						$AnimationPlayer.play("StandRight")
				
				if knockback == false:
					snap_vector = SNAP_DIRECTION * SNAP_LENGTH
				else: 
					snap_vector = Vector2.ZERO
				
				if $ForgivenessTimer.time_left == 0: #just landed
					$LandSound.play()
				$ForgivenessTimer.start(forgiveness_time)

			else: #not on floor
				#yield(get_tree().create_timer(0.1), "timeout")
				pass
			
			if Input.is_action_just_pressed("jump") and $ForgivenessTimer.time_left > 0 or Input.is_action_just_pressed("jump") and is_on_floor():
				$MinimumJumpTimer.start(minimum_jump_time)
				if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
					if abs(_velocity.x) > 82: #since 82.5 is max x velocity, only count as a running jump then   ##Running JUMP CHECKING HERE
						jump_type = "running_jump"
#						jump_speed = long_jump_speed
						jump_starting_move_dir_x = move_dir.x
						$MinimumDirectionTimer.start(minimum_direction_time)
				snap_vector = Vector2.ZERO
				
#				if get_floor_velocity().y < 0: #borrowed this code to prevent sticking
#					position.y += get_floor_velocity().y * get_physics_process_delta_time() - gravity * get_physics_process_delta_time() - 1
				
				$JumpSound.play()
		
			
			if Input.is_action_just_pressed("look_down") and can_fall_through == true and is_on_floor():
				position.y += 8
				
			if knockback:
				if knockback_velocity == Vector2.ZERO:
					knockback_velocity = Vector2(knockback_speed.x * knockback_direction.x, knockback_speed.y * -1)
					_velocity.y = knockback_velocity.y #set knockback y to this ONCE
				
				_velocity.x += knockback_velocity.x
				#print("velocity: ", _velocity)
				#print("knockback velocity: ", knockback_velocity)
				knockback_velocity.x /= 2
				
				if abs(knockback_velocity.x) < 1:
					knockback_velocity = Vector2.ZERO
					knockback = false

			_velocity = calculate_move_velocity(_velocity, move_dir, face_dir, speed, is_jump_interrupted) #special dir was in position 4
			var new_velocity = move_and_slide_with_snap(_velocity, snap_vector, FLOOR_NORMAL, true)
			
			if is_on_wall():
				new_velocity.y = max(_velocity.y, new_velocity.y)
			
			_velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
			
			run_anim_speed = max((abs(_velocity.x)/max_x_speed) * 1.5, 0.1) #run_anim_speed = max((abs(_velocity.x)/max_x_speed) * 1.5, 0.5)
			#print(run_anim_speed)
			animate(move_dir, _velocity)
			
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
				pan_camera_horizontal(face_dir, _velocity)
			if face_dir == Vector2.RIGHT and horizontal_focus == Vector2.LEFT:
				horizontal_focus = Vector2.RIGHT
				pan_camera_horizontal(face_dir, _velocity)
			
			if $Camera2D/TweenHorizontal.is_active():
				$Camera2D/TweenHorizontal.playback_speed = max(abs(_velocity.x)/max_x_speed, 0.5) #second number is minimum camera speed ##thanks me!
			
			if Input.is_action_just_pressed("look_up"):
				if panning_up == false:
					panning_up = true
					pan_camera_vertical(-1)
			if Input.is_action_just_released("look_up"):
				panning_up = false
				home_camera_vertical()
			if Input.is_action_just_pressed("look_down"):
				if panning_down == false:
					panning_down = true
				pan_camera_vertical(1)
			if Input.is_action_just_released("look_down"):
				panning_down = false
				home_camera_vertical()
			
			debug_print(move_dir, face_dir)
		
		else: #debug mode is on
			var move_dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
			_velocity = Vector2(
			debug_speed * move_dir.x,
			debug_speed * move_dir.y)
			_velocity = move_and_slide(_velocity, FLOOR_NORMAL, true)

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

func calculate_move_velocity(linear_velocity: Vector2, move_dir, face_dir, speed, is_jump_interrupted) -> Vector2:
	var out: = linear_velocity
	
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
			out.y = 0.0
		
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
			out.y = 0.0
		
		if move_dir.x == jump_starting_move_dir_x *-1: #if we turn around, cancel minimumdirectiontimer
			$MinimumDirectionTimer.stop()
		
		if not $MinimumDirectionTimer.is_stopped(): #still doing minimum x movement in jump #
			#print("still doing minimum x movement")
			out.x = max_x_speed
			out.x *= jump_starting_move_dir_x
		
		
		elif move_dir.x != 0: #try this asn an if instead if its not working
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
			out.y = 0.0

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


	if abs(out.x) < min_x_velocity:
		out.x = 0
	#print(out)
	return out


func get_input_dir() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_up") - Input.get_action_strength("look_down"))
	

func animate(move_dir, _velocity):
	var player = $AnimationPlayer
	var camera = $Camera2D
	

	
	var texture
	var hframes
	var vframes
	
	var input_dir = get_input_dir()

	
	#var minimum_velocity = 1 #for the difference between moving and standing

	var next_animation: String = ""
	
	if not is_on_ladder:
		if direction_lock == Vector2.ZERO:  #NOT DIRECTION LOCKED
		
			if is_on_floor():
				player.playback_speed = run_anim_speed
				if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					face_dir = Vector2.LEFT
					shoot_dir = Vector2.LEFT
					next_animation = "StandLeft"
				
				elif Input.is_action_pressed("move_left"): #_velocity.x < minimum_velocity * -1: 
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					face_dir = Vector2.LEFT
					
					if Input.is_action_pressed("look_up"):
						shoot_dir = Vector2.UP
						next_animation = "RunLeftLookUp"
					elif Input.is_action_pressed("look_down"):
						shoot_dir = Vector2.LEFT
						next_animation = "RunLeftLookDown"
					else:
						shoot_dir = Vector2.LEFT
						next_animation = "RunLeft"
				
				elif Input.is_action_pressed("move_right"): #_velocity.x > minimum_velocity:
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					face_dir = Vector2.RIGHT
					
					if Input.is_action_pressed("look_up"):
						shoot_dir = Vector2.UP
						next_animation = "RunRightLookUp"
					elif Input.is_action_pressed("look_down"):
						shoot_dir = Vector2.RIGHT
						next_animation = "RunRightLookDown"
					else:
						shoot_dir = Vector2.RIGHT
						next_animation = "RunRight"
				
				else: #not moving on ground
					player.playback_speed = 1 #reset player to normal speed
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					
					if face_dir == Vector2.LEFT:
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "StandLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.LEFT
							next_animation = "StandLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "StandLeft"
				
					elif face_dir == Vector2.RIGHT:
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "StandRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.RIGHT
							next_animation = "StandRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "StandRight"


			else: #airborne
				player.playback_speed = 1 #reset player to normal speed
				
				if _velocity.y < 0: #Rising
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if Input.is_action_pressed("move_left"):
						face_dir = Vector2.LEFT
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "RiseLeft"
					
					elif Input.is_action_pressed("move_right"):
						face_dir = Vector2.RIGHT
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "RiseRight"
							
					elif face_dir == Vector2.LEFT:
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "RiseLeft"
					
					elif face_dir == Vector2.RIGHT:
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "RiseRight"
						
				else: #Falling
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if Input.is_action_pressed("move_left") or face_dir == Vector2.LEFT:
						face_dir = Vector2.LEFT
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "FallLeft"
							
					elif Input.is_action_pressed("move_right") or face_dir == Vector2.RIGHT:
						face_dir = Vector2.RIGHT
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "FallRight"





		elif direction_lock == Vector2.LEFT: #DIRECTION LOCKED LEFT
			face_dir = Vector2.LEFT
			
			if is_on_floor():
					player.playback_speed = run_anim_speed
					
					if Input.is_action_pressed("move_left"):
						texture = load("res://assets/Actor/Player/RecruitRun.png")
						
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RunLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.LEFT
							next_animation = "RunLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "RunLeft"
							
					elif Input.is_action_pressed("move_right"):
						texture = load("res://assets/Actor/Player/RecruitBackrun.png")
						
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "BackrunRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.LEFT
							next_animation = "BackrunRightLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "BackrunRight"
					
					else: #not moving on ground
						player.playback_speed = 1 #reset player to normal speed
						texture = load("res://assets/Actor/Player/RecruitStand.png")
						
						if Input.is_action_pressed("look_up"):
							next_animation = "StandLeftLookUp"
							shoot_dir = Vector2.UP
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.LEFT
							next_animation = "StandLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "StandLeft"


			else: #airborne
				player.playback_speed = 1 #reset player to normal speed
				
				if _velocity.y < 0: #Rising
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if Input.is_action_pressed("move_left"): #Moving Left
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "RiseLeft"
							
					elif Input.is_action_pressed("move_right"): #Moving Right
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseLeftLookUp"
							#next_animation = "BackriseRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseLeftLookDown"
							#next_animation = "BackriseRightLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "RiseLeft"
							#next_animation = "BackriseRight"
							
					else: #not moving rising
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "RiseLeft"


				else: #Falling
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if Input.is_action_pressed("move_left"): #Moving Left
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "FallLeft"
							
					elif Input.is_action_pressed("move_right"): #Moving Right
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallLeftLookUp"
							#next_animation = "BackfallRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallLeftLookDown"
							#next_animation = "BackfallRightLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "FallLeft"
							#next_animation = "BackfallRight"
							
					else: #not moving falling
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallLeftLookDown"
						else:
							shoot_dir = Vector2.LEFT
							next_animation = "FallLeft"





		elif direction_lock == Vector2.RIGHT: #DIRECTION LOCKED RIGHT
			face_dir = Vector2.RIGHT
			
			if is_on_floor():
				player.playback_speed = run_anim_speed
				
				if Input.is_action_pressed("move_left"):
					texture = load("res://assets/Actor/Player/RecruitBackrun.png")
					
					if Input.is_action_pressed("look_up"):
						shoot_dir = Vector2.UP
						next_animation = "BackrunLeftLookUp"
					elif Input.is_action_pressed("look_down"):
						shoot_dir = Vector2.RIGHT
						next_animation = "BackrunLeftLookDown"
					else:
						shoot_dir = Vector2.RIGHT
						next_animation = "BackrunLeft"
						
				elif Input.is_action_pressed("move_right"):
					texture = load("res://assets/Actor/Player/RecruitRun.png")
					
					if Input.is_action_pressed("look_up"):
						shoot_dir = Vector2.UP
						next_animation = "RunRightLookUp"
					elif Input.is_action_pressed("look_down"):
						shoot_dir = Vector2.RIGHT
						next_animation = "RunRightLookDown"
					else:
						shoot_dir = Vector2.RIGHT
						next_animation = "RunRight"
				
				else: #not moving on ground
					player.playback_speed = 1 #reset player to normal speed
					texture = load("res://assets/Actor/Player/RecruitStand.png")
					
					if Input.is_action_pressed("look_up"):
						shoot_dir = Vector2.UP
						next_animation = "StandRightLookUp"
					elif Input.is_action_pressed("look_down"):
						shoot_dir = Vector2.RIGHT
						next_animation = "StandRightLookDown"
					else:
						shoot_dir = Vector2.RIGHT
						next_animation = "StandRight"


			else: #airborne
				player.playback_speed = 1 #reset player to normal speed
				
				if _velocity.y < 0: #Rising
					texture = load("res://assets/Actor/Player/RecruitRise.png")
					
					if Input.is_action_pressed("move_left"): #Moving Left
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseRightLookUp"
							#next_animation = "BackriseLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseRightLookDown"
							#next_animation = "BackriseLeftLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "RiseRight"
							#next_animation = "BackriseLeft"
				
					elif Input.is_action_pressed("move_right"): #Moving Right
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "RiseRight"
					
					else: #not moving rising
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "RiseRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "RiseRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "RiseRight"
				
				else: #Falling
					texture = load("res://assets/Actor/Player/RecruitFall.png")
					
					if Input.is_action_pressed("move_left"): #Moving Left
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallRightLookUp"
							#next_animation = "BackfallLeftLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallRightLookDown"
							#next_animation = "BackfallLeftLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "FallRight"
							#next_animation = "BackfallLeft"
							
					elif Input.is_action_pressed("move_right"): #Moving Right
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "FallRight"
					
					else: #not moving falling
						if Input.is_action_pressed("look_up"):
							shoot_dir = Vector2.UP
							next_animation = "FallRightLookUp"
						elif Input.is_action_pressed("look_down"):
							shoot_dir = Vector2.DOWN
							next_animation = "FallRightLookDown"
						else:
							shoot_dir = Vector2.RIGHT
							next_animation = "FallRight"






	else: #is on ladder
		player.playback_speed = 1 #reset player to normal speed
		if Input.is_action_pressed("move_left"):
			if Input.is_action_pressed("look_up"):
				next_animation = "ClimbLeftLookUp"
			elif Input.is_action_pressed("look_down"):
				next_animation = "ClimbLeftLookDown"
			else:
				next_animation = "ClimbLeft"
		elif Input.is_action_pressed("move_right"):
			if Input.is_action_pressed("look_up"):
				next_animation = "ClimbRightLookUp"
			elif Input.is_action_pressed("look_down"):
				next_animation = "ClimbRightLookDown"
			else:
				next_animation = "ClimbRight"
		else:
			if face_dir.x < 0: #Left
				if Input.is_action_pressed("look_up"):
					next_animation = "ClimbLeftLookUp"
				elif Input.is_action_pressed("look_down"):
					next_animation = "ClimbLeftLookDown"
				else:
					next_animation = "ClimbLeft"
			elif face_dir.x > 0: #Right
				if Input.is_action_pressed("look_up"):
					next_animation = "ClimbRightLookUp"
				elif Input.is_action_pressed("look_down"):
					next_animation = "ClimbRightLookDown"
				else:
					next_animation = "ClimbRight"

	if not player.current_animation == next_animation:
		if next_animation != "":
			change_animation(next_animation, texture)


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

func _on_BonkDetector_body_entered(body, direction):
	if not is_on_floor():
		global_position += (direction * -1) * Vector2(bonk_distance, 0)

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
		#world.get_node("UILayer/HUD").rect_position.x = extra_margin #shift ui over to fit within bars
		
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
		world.get_node("UILayer/HUD").rect_position.x = 0
	
	if OS.get_window_size().y > (bottom - top) * world.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (OS.get_window_size().y - (bottom - top))/2
		camera.limit_top = top - extra_margin
		camera.limit_bottom = bottom  + extra_margin
		#world.get_node("UILayer/HUD").rect_position.y = extra_margin #shift ui over to fit within bars
		
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
		world.get_node("UILayer/HUD").rect_position.y = 0

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

func pan_camera_horizontal(direction, _velocity):
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
		if movement_profile == "chi":
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
		
		yield(get_tree(), "idle_frame")
		var popup = POPUP.instance()
		popup.text = "movement profile: " + movement_profile
		world.get_node("UILayer").add_child(popup)




