extends Node

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")
@onready var sprite = pc.get_node("Sprite2D")
@onready var guns = pc.get_node("GunManager/Guns")
@onready var ap = pc.get_node("AnimationPlayer")

#var saved_move_dir := Vector2.ZERO #for the 2 frame stand
var do_edge_turn: bool
var push_left_wall := false
var push_right_wall := false
var is_dropping = false

func state_process(delta):
	set_player_directions()
	pc.velocity = calc_velocity()
	
	if Input.is_action_just_pressed("debug_testbutton"):
		print(pc.get_node("SlopeRightTester").get_collider())
	
	if (pc.get_node("WallLB").is_colliding() or pc.get_node("WallLT").is_colliding()) and pc.move_dir.x < 0:
		push_left_wall = true
		pc.velocity.x = max(pc.velocity.x, 0)
	else:
		push_left_wall = false
	if (pc.get_node("WallRB").is_colliding() or pc.get_node("WallRT").is_colliding()) and pc.move_dir.x > 0:
		push_right_wall = true
		pc.velocity.x = min(pc.velocity.x, 0)
	else: push_right_wall = false
	
	pc.move_and_slide()
	animate(delta)
	
	
	if not pc.is_on_floor() and not pc.is_in_coyote:
		pc.is_in_coyote = true
		mm.do_coyote_time()
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("look_down") and pc.is_on_ssp and pc.can_input:
		is_dropping = true
		mm.drop()
		return
	elif Input.is_action_pressed("jump") and !is_dropping and pc.can_input:
		mm.jump()
		return


func set_player_directions():
	var input_dir = Vector2.ZERO
	if pc.can_input: 
		input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
	#get move_dir
	pc.move_dir = Vector2(input_dir.x, 0.0)
	#get look_dir
	var look_x = pc.look_dir.x
	if pc.direction_lock != Vector2i.ZERO: #dir lock
		look_x = pc.direction_lock.x
	elif pc.move_dir.x != 0.0: #moving
		look_x = sign(pc.move_dir.x)
	pc.look_dir = Vector2i(look_x, input_dir.y)
	#get shoot_dir
	var shoot_vertically = false
	if pc.look_dir.y < 0.0:
		shoot_vertically = true
	if pc.look_dir.y > 0.0:
		if check_shoot_down():
			shoot_vertically = true
	
	if shoot_vertically: 
		pc.shoot_dir = Vector2(0.0, pc.look_dir.y) 
	else: 
		pc.shoot_dir = Vector2(pc.look_dir.x, 0.0)


func check_shoot_down() -> bool:
	var out = false
	var shoot_down_raycast = pc.get_node("GunManager/ShootDown")
	match pc.look_dir.x:
		-1: shoot_down_raycast.global_position = pc.get_node("GunManager/GunPosLeftDown").global_position
		1: shoot_down_raycast.global_position = pc.get_node("GunManager/GunPosRightDown").global_position
	var length = abs(shoot_down_raycast.position.y) + 12
	shoot_down_raycast.target_position = Vector2(0.0, length)
	if !shoot_down_raycast.is_colliding():
		out = true
	return out

func animate(delta):
	var animation = []
	#var reference_texture
	
	var absolute_left = pc.get_node("AbsoluteLeft").get_collider()
	var absolute_right = pc.get_node("AbsoluteRight").get_collider()
	var stand_close_left = pc.get_node("StandCloseLeft").get_collider()
	var stand_close_right = pc.get_node("StandCloseRight").get_collider()
	var edge_left = pc.get_node("EdgeLeft").get_collider()
	var edge_right = pc.get_node("EdgeRight").get_collider()
	var slope_left = pc.get_node("SlopeLeft").get_collider() and !pc.get_node("SlopeLeftTester").is_colliding()
	var slope_right = pc.get_node("SlopeRight").get_collider() and !pc.get_node("SlopeRightTester").is_colliding()
	
	#var right_edge_falls = pc.get_node("RightEdgeFalls").get_collider()
	#var left_edge_falls = pc.get_node("LeftEdgeFalls").get_collider()

	var edge_is_slope = pc.get_node("EdgeIsSlope").get_collider()
	var edge_is_slight_slope = pc.get_node("EdgeIsSlightSlope").get_collider()
	
	
	### part 2, combining these for conditions always grouped together

	var ssl_par = pc.get_node("SlightSlopeLeft") #left/right refers to slope start point not look dir
	var slight_up_slope_left = pc.get_node("AbsoluteLeft").is_colliding() && ssl_par.get_node("A").is_colliding() && ssl_par.get_node("B").is_colliding() && !ssl_par.get_node("TesterA").is_colliding() && !ssl_par.get_node("TesterB").is_colliding()
	var slight_down_slope_left = pc.get_node("AbsoluteLeft").is_colliding() && ssl_par.get_node("B").is_colliding() && !ssl_par.get_node("TesterB").is_colliding()
	ssl_par = pc.get_node("SlightSlopeRight")
	var slight_up_slope_right = pc.get_node("AbsoluteRight").is_colliding() && ssl_par.get_node("A").is_colliding() && ssl_par.get_node("B").is_colliding() && !ssl_par.get_node("TesterA").is_colliding() && !ssl_par.get_node("TesterB").is_colliding()
	var slight_down_slope_right = pc.get_node("AbsoluteRight").is_colliding() && ssl_par.get_node("B").is_colliding() && !ssl_par.get_node("TesterB").is_colliding()

	#var edge_connections = ["edge_turn", "run"]
	#var edge_turn_connections = ["edge", "run"]
	#var connected_animations = {
		#"edge": ["edge_turn", "run"],
		#"edge_turn": ["edge", "run"],
		#"edge_front": ["edge", "run"],
		#"push": ["stand", "up_slope", "down_slope", "slight_up_slope", "slight_down_slope"],
	#}
	
	
	var look_left = pc.look_dir.x == -1.0
	var look_right = pc.look_dir.x == 1.0
	
			#"edge": ((!absolute_left and !edge_left and !slope_right and absolute_right and look_left && !left_edge_falls) \
				#or (absolute_left and !slope_left and !edge_right and !absolute_right and look_right && !right_edge_falls)) && !edge_is_slight_slope,
		#"edge_front": ((absolute_left and !slope_left and !edge_right and !absolute_right and look_left && !right_edge_falls) \
				#or (!absolute_left and !edge_left and !slope_right and absolute_right and look_right && !left_edge_falls)) && !do_edge_turn && !edge_is_slight_slope,
		#"edge_turn": ((absolute_left and !slope_left and !edge_right and !absolute_right and look_left && !right_edge_falls) \
				#or (!absolute_left and !edge_left and !slope_right and absolute_right and look_right && !left_edge_falls)) && do_edge_turn && !edge_is_slight_slope,
	
	
	
	var conditions = {
		"edge": ((!absolute_left and !edge_left and !slope_right and absolute_right and look_left && !slight_down_slope_right) \
				or (absolute_left and !slope_left and !edge_right and !absolute_right and look_right && !slight_down_slope_left)),
		"edge_front": ((absolute_left and !slope_left and !edge_right and !absolute_right and look_left && !slight_up_slope_left) \
				or (!absolute_left and !edge_left and !slope_right and absolute_right and look_right && !slight_up_slope_right)) && !do_edge_turn  && !edge_is_slope,
		"edge_turn": ((absolute_left and !slope_left and !edge_right and !absolute_right and look_left && !slight_up_slope_left) \
				or (!absolute_left and !edge_left and !slope_right and absolute_right and look_right && !slight_up_slope_right)) && do_edge_turn  && !edge_is_slope,
		"stand": \
			(stand_close_left and edge_right and look_left) or (edge_left and stand_close_right and look_right) and !pc.is_crouching,
		"crouch": ((stand_close_left and absolute_right and look_left) or (absolute_left and stand_close_right and look_right) or (absolute_left and edge_right and look_left) or (edge_left and absolute_right and look_right)) and pc.is_crouching,
		"stand_close": ((edge_left and !stand_close_left and look_left) or (edge_right and !stand_close_right and look_right)) and !pc.is_crouching,
		"stand_close_run_exception": (edge_left and absolute_right and !stand_close_left and look_left) or (absolute_left and edge_right and !stand_close_right and look_right),
		
		"slight_up_slope": (slight_up_slope_left && look_left) || (slight_up_slope_right && look_right),
		"slight_down_slope": (slight_down_slope_right && look_left) || (slight_down_slope_left && look_right),
		"up": (absolute_left and slope_left and !edge_left and !absolute_right and look_left) or (!absolute_left and !edge_right and slope_right and absolute_right and look_right),
		"down": (!absolute_left and !edge_right and slope_right and absolute_right and look_left) or (absolute_left and slope_left and !edge_left and !absolute_right and look_right),
		"stand_to_up_slope": ((absolute_left and !slope_left and !stand_close_right and look_left) \
					or (!stand_close_left and !slope_right and stand_close_right and look_right)) && edge_is_slope
	}

	
	
	#slope crouch prevention
	if conditions["slight_up_slope"] or conditions["slight_down_slope"] or conditions["up"] or conditions["down"]:
		pc.forbid_crouching = true
	else: pc.forbid_crouching = false
	
	match ap.current_animation: #do not use elif here
		"edge":
			if conditions["edge"]:
				animation.append("edge")
			if conditions["edge_front"]:
				animation.append("edge_front")
			if conditions["edge_turn"]:
				animation.append("edge_turn")
			if conditions["stand_close"]:
				animation.append("stand_close")
			if conditions["slight_down_slope"]:
				animation.append("slight_down_slope")
			
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if pc.is_crouching:
					animation.append("crouch_run")
				elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
					animation.append("back_run")
				else:
					animation.append("run")
			

		"edge_front":
			if conditions["edge"]:
				animation.append("edge")
			if conditions["edge_turn"] or conditions["edge_front"]:
				animation.append("edge_front")
			if conditions["stand_close"]:
				animation.append("stand_close")
			if stand_close_left and stand_close_right and !pc.is_crouching: #exception to condition
				animation.append("stand")
			if stand_close_left and stand_close_right and pc.is_crouching: #exception to condition
				animation.append("crouch")
			if conditions["slight_up_slope"]:
				animation.append("slight_up_slope")

		"edge_turn":
			if conditions["edge"]:
				animation.append("edge")
			if conditions["edge_turn"] or conditions["edge_front"]:
				animation.append("edge_turn")
			if conditions["stand_close"]:
				animation.append("stand_close")
			if stand_close_left and stand_close_right and !pc.is_crouching: #exception to condition
				animation.append("stand")
			if stand_close_left and stand_close_right and pc.is_crouching: #exception to condition
				animation.append("crouch")
			if conditions["slight_up_slope"]:
				animation.append("slight_up_slope")
			
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if pc.is_crouching:
					animation.append("crouch_run")
				elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
					animation.append("back_run")
				else:
					animation.append("run")
		
		"stand":
			if conditions["stand_close"]:
				animation.append("stand_close")
			
			if pc.move_dir.x != 0.0 and animation == []: #last case... add room for velocity 
				if push_left_wall or push_right_wall:
					animation.append("push")
				else:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")
			elif pc.move_dir.x == 0.0 and animation == []: #last case number 2
				if pc.is_crouching:
					animation.append("crouch")
				else:
					animation.append("stand")
		
		"crouch":
			if conditions["stand_close"]:
				animation.append("stand_close")
			if pc.move_dir.x != 0.0 and animation == []: #last case... add room for velocity 
				if push_left_wall or push_right_wall:
					animation.append("push")
				else:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")
			elif pc.move_dir.x == 0.0 and animation == []: #last case number 2
				if pc.is_crouching:
					animation.append("crouch")
				else:
					animation.append("stand")
		
		"stand_close":
			if conditions["stand"]:
				animation.append("stand") #TODO: when this goes to stand it goes right to run next frame if turn to make this happen, before returning to stand.
			if (edge_left and !stand_close_left and look_left) or (edge_right and !stand_close_right and look_right): #exception
				animation.append("stand_close")
			if conditions["edge"]:
				animation.append("edge")
			
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if pc.is_crouching:
					animation.append("crouch_run")
				elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
					animation.append("back_run")
				else:
					animation.append("run")
			elif pc.move_dir.x == 0.0 and animation == []: #last case number 2
				if pc.is_crouching:
					animation.append("crouch")
				else:
					animation.append("stand_close")
		
		"push":
			if pc.move_dir.x == 0.0: #not moving
				if !pc.is_crouching:
					animation.append("stand")
				else:
					animation.append("crouch")
			else:
				if !push_left_wall and !push_right_wall:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")
	
		"run":
			animation = run_tree(conditions)
	
		"back_run":
			animation = run_tree(conditions)
	
		"crouch_run": 
			animation = run_tree(conditions)

	
		"stand_peak":
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if pc.is_crouching:
					animation.append("crouch_run")
				elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
					animation.append("back_run")
				else:
					animation.append("run")
		
		"slight_up_slope":
			if conditions["edge"]:
				animation.append("edge")
			if conditions["edge_turn"]:
				animation.append("edge_turn")
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("slight_up_push")
				else:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")
		
		"slight_down_slope":
			if conditions["edge"]:
				animation.append("edge")
			if conditions["edge_turn"]:
				animation.append("edge_turn")
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("slight_down_push")
				else:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")
		
		"up_slope":
			if conditions["edge"]:
				animation.append("edge")
			if conditions["edge_turn"]:
				animation.append("edge_turn")
			if conditions["stand_to_up_slope"]:
				animation.append("stand_to_up_slope")
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("up_push")
				else:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")
		
		"down_slope":
			if conditions["edge"]:
				animation.append("edge")
			if conditions["edge_turn"]:
				animation.append("edge_turn")
			if pc.move_dir.x != 0.0 and animation == []: #last case
				if push_left_wall or push_right_wall:
					animation.append("down_push")
				else:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")

		"slight_up_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("slight_up_slope")
			else:
				if !push_left_wall and !push_right_wall:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")
		
		"slight_down_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("slight_down_slope")
			else:
				if !push_left_wall and !push_right_wall:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")

		"up_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("up_slope")
			else:
				if !push_left_wall and !push_right_wall:
					if pc.is_crouching:
						animation.append("crouch_run")
					elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
						animation.append("back_run")
					else:
						animation.append("run")

		"down_push":
			if pc.move_dir.x == 0.0: #not moving
				animation.append("down_slope")
			else:
				if pc.is_crouching:
					animation.append("crouch_run")
				elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
					animation.append("back_run")
				else:
					animation.append("run")
		
		"stand_to_up_slope":
			if pc.move_dir.x == 0.0: #not moving
				if conditions["stand"]:
					animation.append("stand")
				if conditions["stand_to_up_slope"]:
					animation.append("stand_to_up_slope")
			else:
				if pc.is_crouching:
					animation.append("crouch_run")
				elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
					animation.append("back_run")
				else:
					animation.append("run")

	if animation.is_empty():
		play_animation(ap.current_animation)
		if ap.current_animation == "edge":
			do_edge_turn = true
		else:
			do_edge_turn = false
		
		check_if_offset(ap.current_animation, conditions, delta)
		return
	
	if animation.size() != 1:
		printerr("ERROR: CONFLICT SETTING RUN ANIMATION FROM ", ap.current_animation, " to ", animation)
		return
	#if animation[0] == ap.current_animation:
		#return
	
	if animation[0] == "edge":
		do_edge_turn = true
	else:
		do_edge_turn = false
	
	check_if_offset(animation[0], conditions, delta)
	play_animation(animation[0])
	
	#saved_move_dir = pc.move_dir #for 2 frame stand

### ANIMATION TREES ###

func run_tree(conditions) -> Array:
	var out = []
	if pc.move_dir.x == 0.0: #not moving
		if conditions["stand_close_run_exception"]:
			out.append("stand_close")
		if conditions["edge"]:
			out.append("edge")
		if conditions["edge_front"]:
			out.append("edge_front")
		if conditions["edge_turn"]:
			out.append("edge_turn")
		if conditions["stand"]:
			out.append("stand")
		if conditions["crouch"]:
			out.append("crouch")
		#if !absolute_left and !absolute_right:
			#out.append("stand_peak")
		if conditions["slight_up_slope"]:
			out.append("slight_up_slope")
		if conditions["slight_down_slope"]:
			out.append("slight_down_slope")
		if conditions["up"]:
			out.append("up_slope")
		if conditions["down"]:
			out.append("down_slope")
		if conditions["stand_to_up_slope"]:
			out.append("stand_to_up_slope")
	else:
		if push_left_wall or push_right_wall:
			if conditions["slight_up_slope"]:
				out.append("slight_up_push")
			elif conditions["slight_down_slope"]:
				out.append("slight_down_push")
			elif conditions["up"]:
				out.append("up_push")
			elif conditions["down"]:
				out.append("down_push")
			else:
				out.append("push")
		else:
			if pc.is_crouching:
				out.append("crouch_run")
			elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
				out.append("back_run")
			else:
				out.append("run")
	return out




func check_if_offset(animation, conditions, delta):
	if animation == "run" or animation == "back_run":
		var is_slight_slope = conditions["slight_up_slope"] or conditions["slight_down_slope"]
		var is_slope = conditions["up"] or conditions["down"]
		do_run_animation_offset(is_slight_slope, is_slope, delta)
	else:
		sprite.gun_pos_offset = Vector2.ZERO
		do_animation_sprite_offset(animation, delta)

func do_animation_sprite_offset(animation, delta):
	var offsets = {
		"stand_peak": Vector2(0, 1),
		"slight_up_slope": Vector2(0, 4),
		"slight_down_slope": Vector2(0, 4),
		"up_slope": Vector2(0, 9),
		"down_slope": Vector2(0, 7),
		"slight_up_push": Vector2(0, 6),
		"slight_down_push": Vector2(0, 6),
		"up_push": Vector2(0, 9),
		"down_push": Vector2(0, 8),
		"stand_to_up_slope": [Vector2(0, 9), Vector2(0, 2)],
	}
	
	if offsets.has(animation): #only works if these lerp animations can't become eachother as we never reset sprite.position
		if offsets[animation] is Array:
			var t = calc_stand_to_slope_lerp_delta(Vector2(pc.look_dir.x, 0))
			var translation = offsets[animation][0].lerp(offsets[animation][1], t) #interpolated
			var final_position = Vector2(0, -16) + translation
			var speed = 20.0
			sprite.position = sprite.position.lerp(final_position, delta * speed)
			sprite.gun_pos_offset = sprite.position - Vector2(0, -16)
		else:
			sprite.position = Vector2(0, -16)
			sprite.position += offsets[animation]
	else:
		sprite.position = Vector2(0, -16)



func do_run_animation_offset(is_slight_slope, is_slope, delta):
	var run_offsets = {
		"is_slight_slope": Vector2(0, 3),
		"is_slope": Vector2(0, 4),
	}
	var offset:= Vector2.ZERO
	if is_slight_slope:
		offset = run_offsets["is_slight_slope"]
	elif is_slope:
		offset = run_offsets["is_slope"]
	var final_position = Vector2(0, -16) + offset
	var speed = 20.0
	sprite.position = sprite.position.lerp(final_position, delta * speed)
	sprite.gun_pos_offset = sprite.position - Vector2(0, -16)


func calc_stand_to_slope_lerp_delta(direction) -> float: #try with half of these since we can lerp
	var out = 0.0
	var par = pc.get_node("StandToSlopeLerpDelta")
	
	
	if direction == Vector2.LEFT:
		if par.get_node("A").is_colliding(): out = 0.1
		if par.get_node("B").is_colliding(): out = 0.2
		if par.get_node("C").is_colliding(): out = 0.3
		if par.get_node("D").is_colliding(): out = 0.4
		if par.get_node("E").is_colliding(): out = 0.5
		if par.get_node("F").is_colliding(): out = 0.6
		if par.get_node("G").is_colliding(): out = 0.7
		if par.get_node("H").is_colliding(): out = 0.8
		if par.get_node("I").is_colliding(): out = 0.9
		if par.get_node("J").is_colliding(): out = 1.0
	elif direction == Vector2.RIGHT:
		if par.get_node("K").is_colliding(): out = 0.1
		if par.get_node("J").is_colliding(): out = 0.2
		if par.get_node("I").is_colliding(): out = 0.3
		if par.get_node("H").is_colliding(): out = 0.4
		if par.get_node("G").is_colliding(): out = 0.5
		if par.get_node("F").is_colliding(): out = 0.6
		if par.get_node("E").is_colliding(): out = 0.7
		if par.get_node("D").is_colliding(): out = 0.8
		if par.get_node("C").is_colliding(): out = 0.9
		if par.get_node("B").is_colliding(): out = 1.0
	return out

func play_animation(animation):
	#for runtime, set the frame counts before the animation starts
	var reference_texture = load("res://assets/Player/" + animation.to_pascal_case() + ".png")
	sprite.hframes = int(reference_texture.get_width() / 32.0)
	sprite.vframes = int(reference_texture.get_height() / 32.0)
	ap.speed_scale = 1.0
	var do_blending = false
	
	var run_group = ["run", "crouch_run", "back_run"]
	#var edge_group = ["edge", "edge_front"] #dont blend these
	var stand_group = ["stand", "stand_close", "push", "crouch", "edge_turn", "up_slope", "down_slope", "slight_up_slope", "slight_down_slope", "stand_peak", "stand_to_up_slope"]
	
	if run_group.has(animation):
		ap.speed_scale = max((abs(pc.velocity.x)/mm.speed.x) * 2.0, 0.1)
		if run_group.has(ap.current_animation):
			do_blending = true
	if stand_group.has(animation):
		if stand_group.has(ap.current_animation):
			do_blending = true

	var vframe = get_vframe()
	sprite.frame_coords.y = vframe


	var blend_time = 0.0
	if not ap.is_playing() or ap.current_animation != animation:
		if do_blending:
			#print("blending animation")
			if (ap.current_animation == "back_run" and animation == "run") or (ap.current_animation == "run" and animation == "back_run"): #special blend rules
				var new_frame = ((12 - int(floor(ap.current_animation_position * 10))) % 12) + 1
				blend_time = new_frame / 10.0
				#print("blending run from: ",ap.current_animation_position, ", to: ", blend_time)
			else:
				blend_time = ap.current_animation_position #only blend certain animations
			
		ap.stop()
		ap.play(animation, blend_time, 1.0)
		if blend_time != 0.0:
			ap.seek(blend_time, true)





### GETTERS ###

func calc_velocity():
	var out = pc.velocity
	#Y
	out.y += mm.gravity * get_physics_process_delta_time()
	#X
	if pc.move_dir.x != 0.0:
		var max_speed = mm.speed.x
		if pc.is_crouching:
			max_speed = mm.crouch_speed

		if pc.move_dir.x != sign(out.x):
			out.x = 0.0

		var value = out.x + mm.acceleration * pc.move_dir.x
		# Make sure the acceleration does not surpass max speed
		out.x = clampf(value, -max_speed, max_speed)
	# ground friction kicks in if you let go of a directional key
	else:
		out.x = lerp(out.x, 0.0, mm.ground_cof)
	if abs(out.x) < mm.min_x_velocity: #clamp velocity
		out.x = 0
	return out


func get_vframe() -> int:
	var out = 0
	if sprite.vframes == 8:
		match pc.look_dir.x:
			-1: out = 0
			1: out = 4
		if pc.shoot_dir.y < 0.0:
			out += 1
		elif pc.shoot_dir.y > 0.0:
			out += 2
		elif pc.shoot_dir.y == 0.0 and pc.look_dir.y == 1:
			out += 3
	if sprite.vframes == 6:
		match pc.look_dir.x:
			-1: out = 0
			1: out = 3
		if pc.shoot_dir.y < 0.0:
			out += 1
		elif pc.shoot_dir.y > 0.0:
			out += 2
	return out



### STATE ###

func enter(): #TODO: consider setting these back after exiting or just set these on setup
	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)
	pc.floor_snap_length = 8.0
	pc.floor_max_angle = 0.8 #well over 45degrees so we can have a lower safe_margin
	pc.safe_margin = 0.008 #may cause issues this low
	do_edge_turn = false
	play_animation("run")
func exit():
	sprite.position = Vector2i(0.0, -16.0)
	is_dropping = false
