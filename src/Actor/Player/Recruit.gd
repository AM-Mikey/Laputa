extends Player

const BLACKBAR = preload("res://src/Utility/BlackBar.tscn")

export var run_anim_speed = 1.25
export var acceleration = 50
export var max_x_speed = 82.5
export var jump_speed = 195
export var minimum_jump_time = 0.1
export var ground_cof = 0.2
export var air_cof = 0.05

var horizontal_focus = Vector2.LEFT
var homing_camera = false
var panning_up = false
var panning_down = false

var direction_lock = Vector2.ZERO
var starting_direction #for acceleration
var bonk_distance = 4

onready var animation_tree = get_node("AnimationTree")
onready var animation_mode = animation_tree.get("parameters/playback")
onready var world = get_tree().get_root().get_node("World")

func _physics_process(delta):
	if disabled != true:
		if colliding == true: #skip this entire thing if we're in debug mode
			
			var is_jump_interrupted = false
			if $MinimumJumpTimer.time_left == 0:
				is_jump_interrupted = not Input.is_action_pressed("jump") and _velocity.y < 0.0
				
			var is_dodge_interrupted = Input.is_action_just_released("dodge") and _velocity.y < 0.0
			var move_dir = get_move_dir()
			var look_rot = $LookRot.rotation_degrees
			var look_dir = get_look_dir(look_rot)
			var special_dir = get_special_dir(move_dir, look_dir)
			var bullet_pos = $BulletVector.global_position
			var effect_pos = $WeaponSprite.position
			var bullet_rot = $BulletVector.rotation_degrees
			
			if is_on_ceiling():
				#if bonk_dir == Vector2.ZERO:
				$BonkSound.play()
			
			if is_on_floor(): #start forgiveness timer on any frame they're on
				$ForgivenessTimer.start(forgiveness_time)
				if end_knockback_ready:
					special_dir = Vector2.ZERO
					knockback = false
					end_knockback_ready = false
			else: #not on floor
				special_dir.y = 0
				do_while_airborne()
			
			if Input.is_action_just_pressed("jump") and $ForgivenessTimer.time_left > 0 or Input.is_action_just_pressed("jump") and is_on_floor():
				$MinimumJumpTimer.start(minimum_jump_time)
			
			if Input.is_action_just_pressed("dodge") and $DodgeTimer.time_left == 0:
				$DodgeTimer.start(dodge_time)
			
			if Input.is_action_just_pressed("look_down") and can_fall_through == true and is_on_floor():
				position.y += 8
				

			_velocity = calculate_move_velocity(_velocity, move_dir, look_dir, special_dir, speed, is_jump_interrupted, is_dodge_interrupted)
			_velocity = move_and_slide(_velocity, FLOOR_NORMAL, true)
			
			
			animate(move_dir, look_dir, _velocity)
			
			if Input.is_action_pressed("fire_manual"): #holding
				$WeaponManager.manual_fire(bullet_pos, effect_pos, bullet_rot)
			if Input.is_action_pressed("fire_automatic"): #holding
				$WeaponManager.automatic_fire(bullet_pos, effect_pos, bullet_rot)
			if Input.is_action_just_pressed("fire_automatic"): #only on first pressed
				direction_lock = look_dir
			if Input.is_action_just_released("fire_manual"):
				$WeaponManager.release_fire()
			if Input.is_action_just_released("fire_automatic"): 
				$WeaponManager.release_fire()
				direction_lock = Vector2.ZERO
			
			if look_dir == Vector2.LEFT and horizontal_focus == Vector2.RIGHT:
				horizontal_focus = Vector2.LEFT
				pan_camera_horizontal(look_dir, _velocity)
			if look_dir == Vector2.RIGHT and horizontal_focus == Vector2.LEFT:
				horizontal_focus = Vector2.RIGHT
				pan_camera_horizontal(look_dir, _velocity)
			
			if $Camera2D/TweenHorizontal.is_active():
				$Camera2D/TweenHorizontal.playback_speed = max(abs(_velocity.x)/max_x_speed, 0) #second number is minimum camera speed
			
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
			
			debug(move_dir, look_dir)
		
		else: #debug mode is on
			var move_dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
			_velocity = Vector2(
			debug_speed * move_dir.x,
			debug_speed * move_dir.y)
			_velocity = move_and_slide(_velocity, FLOOR_NORMAL, true)

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

func get_look_dir(look_rot) -> Vector2:
	if look_rot == 90: #Left
		return Vector2(-1, 0)
	elif look_rot == 270 or look_rot == -90: #Right
		return Vector2(1, 0)
	elif look_rot == 180: #Up
		return Vector2(0, -1)
	elif look_rot == 0: #Down
		return Vector2(0, 1)
	else:
		print ("ERROR: Cant get look direction!")
		return Vector2.LEFT
		

func get_special_dir(move_dir, look_dir) -> Vector2:
	if Input.is_action_pressed("dodge"):
		return Vector2(look_dir.x * -1, -1.0)
	if knockback == true:
		#print("knockback in direction: ", knockback_direction)
		return Vector2(knockback_direction.x, -1.0)
	else:
		return Vector2.ZERO

func calculate_move_velocity(linear_velocity: Vector2, move_dir, look_dir, special_dir, speed, is_jump_interrupted, is_dodge_interrupted) -> Vector2:
	var out: = linear_velocity
	
	var friction = false
	
	if is_on_ladder:
		out.y = move_dir.y * jump_speed/2
		#out.x = min(abs(out.x) + acceleration, max_x_speed)
		#out.x *= move_dir.x
	
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

	
	elif special_dir == Vector2.ZERO: #normal, no special
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


	elif knockback == true: #with special, knockback #MASSIVE ISSUES HERE WITH ACCELERATION
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0 or special_dir.y < 0: 
			if move_dir.y != 0:
				out.y = jump_speed * ((move_dir.y * knockback_mod.y * special_dir.y)/2)
			else:
				out.y = jump_speed * (special_dir.y * knockback_mod.y)
		if is_jump_interrupted:
			out.y = 0.0
		
		if move_dir.x != 0:
			out.x = max_x_speed * ((move_dir.x * knockback_mod.x * special_dir.x)/2) 
		else:
			out.x = max_x_speed * (special_dir.x * knockback_mod.x)
			friction = true
	


#	else: #with special, no knockback
#		out.y += gravity * get_physics_process_delta_time()
#		if move_dir.y < 0 or special_dir.y < 0: 
#			if move_dir.y != 0:
#				out.y = speed.y * ((move_dir.y * special_dir.y)/2)
#			else:
#				out.y = speed.y * special_dir.y
#		if is_jump_interrupted:
#			out.y = 0.0
#
#		if move_dir.x != 0:
#			out.x = speed.x * ((move_dir.x * special_dir.x)/2)
#		else:
#			out.x = speed.x * special_dir.x
#			friction = true



	if is_on_floor():
		if friction == true:
			out.x = lerp(out.x, 0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0, air_cof)

	#print(out)
	return out

func do_while_airborne():
	yield(get_tree().create_timer(0.1), "timeout")
	end_knockback_ready = true

func get_input_dir() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_up") - Input.get_action_strength("look_down"))
	

func animate(move_dir, look_dir, _velocity):
	var player = $AnimationPlayer
	var camera = $Camera2D
	
	var input_dir = get_input_dir()
	#print(input_dir)
	#print(look_dir)

	var next_animation: String = ""
	
	
	if direction_lock == Vector2.ZERO:  #NOT DIRECTION LOCKED
	
		if is_on_floor():
			#player.playback_speed = run_anim_speed
			if Input.is_action_pressed("move_left"):
				if Input.is_action_pressed("look_up"):
					next_animation = "RunLeftLookUp"
				elif Input.is_action_pressed("look_down"):
					next_animation = "RunLeftLookDown"
				else:
					next_animation = "RunLeft"
			
			elif Input.is_action_pressed("move_right"):
				if Input.is_action_pressed("look_up"):
					next_animation = "RunRightLookUp"
				elif Input.is_action_pressed("look_down"):
					next_animation = "RunRightLookDown"
				else:
					next_animation = "RunRight"

			else: #not moving on ground
				player.playback_speed = 1 #reset player to normal speed
				if look_dir.x < 0: #Left
					if Input.is_action_pressed("look_up"):
						next_animation = "StandLeftLookUp"
					elif Input.is_action_pressed("look_down"):
						next_animation = "StandLeftLookDown"
					else:
						next_animation = "StandLeft"

				elif look_dir.x > 0: #Right
					if Input.is_action_pressed("look_up"):
						next_animation = "StandRightLookUp"
					elif Input.is_action_pressed("look_down"):
						next_animation = "StandRightLookDown"
					else:
						next_animation = "StandRight"
		else: #airborne
			player.playback_speed = 1 #reset player to normal speed
			
			if _velocity.y < 0: #Rising
				if Input.is_action_pressed("move_left"): #Moving Left
					if Input.is_action_pressed("look_up"):
						next_animation = "RiseLeftLookUp"
					elif Input.is_action_pressed("look_down"):
						next_animation = "RiseLeftLookDown"
					else:
						next_animation = "RiseLeft"
				elif Input.is_action_pressed("move_right"): #Moving Right
					if Input.is_action_pressed("look_up"):
						next_animation = "RiseRightLookUp"
					elif Input.is_action_pressed("look_down"):
						next_animation = "RiseRightLookDown"
					else:
						next_animation = "RiseRight"
			else: #Falling
				if Input.is_action_pressed("move_left"): #Moving Left
					if Input.is_action_pressed("look_up"):
						next_animation = "FallLeftLookUp"
					elif Input.is_action_pressed("look_down"):
						next_animation = "FallLeftLookDown"
					else:
						next_animation = "FallLeft"
				elif Input.is_action_pressed("move_right"): #Moving Right
					if Input.is_action_pressed("look_up"):
						next_animation = "FallRightLookUp"
					elif Input.is_action_pressed("look_down"):
						next_animation = "FallRightLookDown"
					else:
						next_animation = "FallRight"
#			elif look_dir.x < 0:					 #Looking Left
#				if Input.is_action_pressed("look_up"):
#					next_animation = "StandLeftAimUp"
#				elif Input.is_action_pressed("look_down"):
#					next_animation = "StandLeftAimDown"
#				else:
#					next_animation = "StandRightAimDown"
#
#			elif look_dir.x > 0: 					#Looking Right
#				if Input.is_action_pressed("look_up"):
#					next_animation = "RunRightAimUp"
#				elif Input.is_action_pressed("look_down"):
#					next_animation = "StandRightAimUp"
#				else:
#					next_animation = "AimSmallRight"
	if not player.current_animation == next_animation:
		if next_animation != "":
			change_animation(next_animation)


func change_animation(next_animation):
	var player = $AnimationPlayer
	var old_time = $AnimationPlayer.current_animation_position
	
	
	player.play(next_animation)
	#$AnimationPlayer.seek(old_time)
#			else: #not moving on ground
#				player.playback_speed = 1 #reset player to normal speed
#				if look_dir.x < 0: #Left
#					if Input.is_action_pressed("look_up"):
#						player.play("StandLeftAimUp")
#					elif Input.is_action_pressed("look_down"):
#						player.play("AimSmallLeft")
#					else:
#						player.play("AimSmallLeft")
#
#				elif look_dir.x > 0: #Right
#					if Input.is_action_pressed("look_up"):
#						player.play("StandRightAimUp")
#					elif Input.is_action_pressed("look_down"):
#						player.play("AimSmallRight")
#					else:
#						player.play("AimSmallRight")
#		else: #airborne
#			player.playback_speed = 1 #reset player to normal speed
#
#			if Input.is_action_pressed("move_left"): #Moving Left
#				if Input.is_action_pressed("look_up"):
#					player.play("RunLeftAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunLeftAimDown")
#				else:
#						player.play("RunLeft")
#			elif Input.is_action_pressed("move_right"): #Moving Right
#				if Input.is_action_pressed("look_up"):
#					player.play("RunRightAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunRightAimDown")
#				else:
#						player.play("RunRight")
#			elif look_dir.x < 0:					 #Looking Left
#				if Input.is_action_pressed("look_up"):
#					player.play("StandLeftAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("StandLeftAimDown")
#				else:
#					player.play("StandRightAimDown")
#
#			elif look_dir.x > 0: 					#Looking Right
#				if Input.is_action_pressed("look_up"):
#					player.play("RunRightAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("StandRightAimUp")
#				else:
#					player.play("AimSmallRight")
#
#	elif direction_lock == Vector2.LEFT: #DIRECTION LOCKED LEFT
#		if is_on_floor():
#			#moving on ground
#			player.playback_speed = run_anim_speed #set player speed to run_anim_speed
#			if Input.is_action_pressed("move_left"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunLeftAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunLeft")
#				else:
#					player.play("RunLeft")
#
#			elif Input.is_action_pressed("move_right"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunRightLookLeftAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunRightLookLeft")
#				else:
#					player.play("RunRightLookLeft")
#
#			else: #not moving on ground
#				player.playback_speed = 1 #reset player to normal speed
#				if look_dir.x < 0: #Left
#					if Input.is_action_pressed("look_up"):
#						player.play("StandLeftAimUp")
#					elif Input.is_action_pressed("look_down"):
#						player.play("AimSmallLeft")
#					else:
#						player.play("AimSmallLeft")
#
#				elif look_dir.x > 0: #Right
#					if Input.is_action_pressed("look_up"):
#						player.play("StandRightAimUp")
#					elif Input.is_action_pressed("look_down"):
#						player.play("AimSmallRight")
#					else:
#						player.play("AimSmallRight")
#		else: #airborne
#			player.playback_speed = 1 #reset player to normal speed
#			if Input.is_action_pressed("move_left"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunLeftAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunLeftAimDown")
#				else:
#						player.play("RunLeft")
#			elif Input.is_action_pressed("move_right"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunRightLookLeftAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunRightLookLeftAimDown")
#				else:
#						player.play("RunRightLookLeft")
#	else: #DIRECTION LOCKED RIGHT
#		if is_on_floor():
#			#moving on ground
#			player.playback_speed = run_anim_speed #set player speed to run_anim_speed
#			if Input.is_action_pressed("move_left"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunLeftLookRightAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunLeftLookRight")
#				else:
#					player.play("RunLeftLookRight")
#
#			elif Input.is_action_pressed("move_right"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunRightAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunRight")
#				else:
#					player.play("RunRight")
#
#			else: #not moving on ground
#				player.playback_speed = 1 #reset player to normal speed
#				if look_dir.x < 0: #Left
#					if Input.is_action_pressed("look_up"):
#						player.play("StandLeftAimUp")
#					elif Input.is_action_pressed("look_down"):
#						player.play("AimSmallLeft")
#					else:
#						player.play("AimSmallLeft")
#
#				elif look_dir.x > 0: #Right
#					if Input.is_action_pressed("look_up"):
#						player.play("StandRightAimUp")
#					elif Input.is_action_pressed("look_down"):
#						player.play("AimSmallRight")
#					else:
#						player.play("AimSmallRight")
#		else: #airborne
#			player.playback_speed = 1 #reset player to normal speed
#			if Input.is_action_pressed("move_left"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunLeftLookRightAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunLeftLookRightAimDown")
#				else:
#						player.play("RunLeftLookRight")
#			elif Input.is_action_pressed("move_right"):
#				if Input.is_action_pressed("look_up"):
#					player.play("RunRightAimUp")
#				elif Input.is_action_pressed("look_down"):
#					player.play("RunRightAimDown")
#				else:
#						player.play("RunRight")

func _on_BonkDetector_body_entered(body, direction):
	#print("player bonked head")
	global_position += (direction * -1) * Vector2(bonk_distance, 0)

func _on_limit_camera(left, right, top, bottom):
	var camera = $Camera2D
	
	var bars = get_tree().get_nodes_in_group("BlackBars")
	for b in bars:
		b.free()
	
	
	if  OS.get_window_size().x > (right - left) * world.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = (OS.get_window_size().x - (right - left))/2
		camera.limit_left = left - extra_margin
		camera.limit_right = right + extra_margin
		world.get_node("UILayer/HUD").rect_position.x = extra_margin
		
		var left_pillar = BLACKBAR.instance()
		left_pillar.name = "BlackBarLeft"
		left_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		world.get_node("UILayer").add_child(left_pillar)
		
		var right_pillar = BLACKBAR.instance()
		right_pillar.name = "BlackBarRight"
		right_pillar.rect_size = Vector2(extra_margin, OS.get_window_size().y)
		right_pillar.rect_position = Vector2((right - left) + extra_margin, 0)
		world.get_node("UILayer").add_child(right_pillar)
		
	else:
		camera.limit_left = left
		camera.limit_right = right
		world.get_node("UILayer/HUD").rect_position.x = 0
	
	if OS.get_window_size().y > (bottom - top) * world.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (OS.get_window_size().y - (bottom - top))/2
		camera.limit_top = top - extra_margin
		camera.limit_bottom = bottom  + extra_margin
		world.get_node("UILayer/HUD").rect_position.y = extra_margin
		
		var top_pillar = BLACKBAR.instance()
		top_pillar.name = "BlackBarTop"
		top_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		world.get_node("UILayer").add_child(top_pillar)
		
		var bottom_pillar = BLACKBAR.instance()
		bottom_pillar.name = "BlackBarRight"
		bottom_pillar.rect_size = Vector2(OS.get_window_size().x, extra_margin)
		bottom_pillar.rect_position = Vector2(0, (bottom - top) + extra_margin)
		world.get_node("UILayer").add_child(bottom_pillar)
	
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
	
	var camera_pan_distance = 2.5 / world.resolution_scale
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




