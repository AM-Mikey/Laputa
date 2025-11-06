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

	jump_processing()

##Processes jumps and platform drops
func jump_processing():
	if world.has_node("UILayer/UIGroup/DialogBox"):
		if !world.get_node("UILayer/UIGroup/DialogBox").is_exiting:
			return #prevent the jump while db exists and is not exiting, this does allow holdjumping, though

	if inp.pressed("jump") and Input.is_action_pressed("look_down") and pc.is_on_ssp and pc.can_input:
		is_dropping = true
		mm.drop()
	elif !is_dropping and pc.can_input:
		if inp.pressed("jump"):
			mm.jump()
	elif inp.buttonconfig.holdjumping:
		if inp.held("jump"):
			mm.jump()



func set_player_directions():
	var input_dir:Vector2 = Vector2(0.0,0.0)
	if pc.can_input: input_dir = inp.analogstick
	#get move_dir
	pc.move_dir = Vector2(input_dir.x, 0.0)
	#get look_dir
	var look_x = pc.look_dir.x
	if pc.direction_lock != Vector2i.ZERO: #dir lock
		look_x = pc.direction_lock.x
	elif pc.move_dir.x != 0.0: #moving
		look_x = sign(pc.move_dir.x)
	pc.look_dir = Vector2i(look_x, 0)
	if abs(input_dir.y) >= inp.Y_axis_shoot_deadzone:
		pc.look_dir.y = sign(input_dir.y)

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



### ANIMATION ###

func animate(delta):
	var next_animations = []
	#var reference_texture

	var absolute_left = pc.get_node("AbsoluteLeft").is_colliding()
	var absolute_right = pc.get_node("AbsoluteRight").is_colliding()
	var valley_left = pc.get_node("ValleyLeft").is_colliding()
	var valley_right = pc.get_node("ValleyRight").is_colliding()
	var peak_left = pc.get_node("PeakLeft").is_colliding()
	var peak_right = pc.get_node("PeakRight").is_colliding()
	var slight_slope_peak_left = pc.get_node("SlightSlopePeakLeft").is_colliding()
	var slight_slope_peak_right = pc.get_node("SlightSlopePeakRight").is_colliding()
	var stand_close_left = pc.get_node("StandCloseLeft").is_colliding()
	var stand_close_right = pc.get_node("StandCloseRight").is_colliding()
	var edge_left = pc.get_node("EdgeLeft").is_colliding()
	var edge_right = pc.get_node("EdgeRight").is_colliding()
	var left_edge_is_world = pc.get_node("LeftEdgeIsWorld").is_colliding()
	var right_edge_is_world = pc.get_node("RightEdgeIsWorld").is_colliding()

	var look_left = pc.look_dir.x == -1.0
	var look_right = pc.look_dir.x == 1.0

	var vector_slope_tolerance = Vector2(0.1, 0.1)

	var left_normal = Vector2.ZERO
	var right_normal = Vector2.ZERO
	var left_negative_slope := false
	var left_positive_slope := false
	var left_slight_negative_slope := false
	var left_slight_positive_slope := false
	var left_no_slope := false
	var left_walkable_negative_slope := false
	var left_walkable_positive_slope := false
	var right_negative_slope := false
	var right_positive_slope := false
	var right_slight_negative_slope := false
	var right_slight_positive_slope := false
	var right_no_slope := false
	var right_walkable_negative_slope := false
	var right_walkable_positive_slope := false

	if pc.get_node("LeftNormalFinder").is_colliding():
		left_normal = pc.get_node("LeftNormalFinder").get_collision_normal()
		left_negative_slope = abs(left_normal - Vector2(0.7, -0.7)) < vector_slope_tolerance #45 deg
		left_positive_slope = abs(left_normal - Vector2(-0.7, -0.7)) < vector_slope_tolerance #45 deg
		left_slight_negative_slope = abs(left_normal - Vector2(0.45, -0.89)) < vector_slope_tolerance #22.5 deg
		left_slight_positive_slope = abs(left_normal - Vector2(-0.45, -0.89)) < vector_slope_tolerance #22.5 deg
		left_no_slope = abs(left_normal - Vector2(0.0, -1.0)) < vector_slope_tolerance #0 deg
		left_walkable_negative_slope = left_negative_slope || left_slight_negative_slope
		left_walkable_positive_slope = left_positive_slope || left_slight_positive_slope

	if pc.get_node("RightNormalFinder").is_colliding():
		right_normal = pc.get_node("RightNormalFinder").get_collision_normal()
		right_negative_slope = abs(right_normal - Vector2(0.7, -0.7)) < vector_slope_tolerance #45 deg
		right_positive_slope = abs(right_normal - Vector2(-0.7, -0.7)) < vector_slope_tolerance #45 deg
		right_slight_negative_slope = abs(right_normal - Vector2(0.45, -0.89)) < vector_slope_tolerance #22.5 deg
		right_slight_positive_slope = abs(right_normal - Vector2(-0.45, -0.89)) < vector_slope_tolerance #22.5 deg
		right_no_slope = abs(right_normal - Vector2(0.0, -1.0)) < vector_slope_tolerance #0 deg
		right_walkable_negative_slope = right_negative_slope || right_slight_negative_slope
		right_walkable_positive_slope = right_positive_slope || right_slight_positive_slope

	var left_nothing = left_normal == Vector2(0, 0) #air
	var right_nothing = right_normal == Vector2(0, 0) #air

	var conditions = {
		"edge":
			(!absolute_left && !edge_left && absolute_right && look_left && !left_walkable_positive_slope && !left_edge_is_world) || \
			(absolute_left && !edge_right && !absolute_right && look_right && !right_walkable_negative_slope && !right_edge_is_world) || \
			(!left_edge_is_world && right_walkable_negative_slope && look_left) || \
			(left_walkable_positive_slope && !right_edge_is_world && look_right),
		"edge_front":
			((absolute_left && !edge_right && !absolute_right && look_left && !right_walkable_negative_slope && !right_edge_is_world) || \
			(!absolute_left && !edge_left && absolute_right && look_right && !left_walkable_positive_slope && !left_edge_is_world) || \
			(left_walkable_positive_slope && !right_edge_is_world && look_left) || \
			(!left_edge_is_world && right_walkable_negative_slope && look_right)) && !do_edge_turn,
		"edge_turn":
			((absolute_left && !edge_right && !absolute_right && look_left && !right_walkable_negative_slope && !right_edge_is_world) || \
			(!absolute_left && !edge_left && absolute_right && look_right && !left_walkable_positive_slope && !left_edge_is_world) || \
			(left_walkable_positive_slope && !right_edge_is_world && look_left) || \
			(!left_edge_is_world && right_walkable_negative_slope && look_right)) && do_edge_turn,
		"stand":
			(stand_close_left && edge_left && edge_right && stand_close_right && !pc.is_crouching),
		"crouch":
			pc.is_crouching,
		"stand_close":
			((edge_left && !stand_close_left && look_left && right_no_slope) || \
			(edge_right && !stand_close_right && look_right && left_no_slope)) && !pc.is_crouching,
		"stand_close_reverse":
			((stand_close_left && edge_right && !stand_close_right && look_left && left_no_slope) || \
			(!stand_close_left && edge_left && stand_close_right && look_right && right_no_slope)) && !pc.is_crouching,
		"slight_up_slope":
			(left_slight_negative_slope && right_slight_negative_slope && look_left) || \
			(left_slight_positive_slope && right_slight_positive_slope && look_right) || \
			(left_nothing && left_edge_is_world && right_slight_negative_slope && look_left) || \
			(left_slight_positive_slope && right_edge_is_world && right_nothing && look_right) || \
			(left_slight_negative_slope && right_edge_is_world && right_nothing && look_left) || \
			(right_slight_positive_slope && left_edge_is_world && left_nothing && look_right) || \
			(left_slight_negative_slope && right_walkable_positive_slope && look_left && !valley_right) || \
			(left_walkable_negative_slope && right_slight_positive_slope && look_right && !valley_left) || \
			(left_walkable_positive_slope && right_slight_negative_slope && look_left && slight_slope_peak_left && !slight_slope_peak_right) || \
			(left_slight_positive_slope && right_walkable_negative_slope && look_right && slight_slope_peak_right && !slight_slope_peak_left), #2 for upslope into air #2 for air to upslope #2 for valley 2 for peak
		"slight_down_slope":
			(left_slight_positive_slope && right_slight_positive_slope && look_left) || \
			(left_slight_negative_slope && right_slight_negative_slope && look_right) || \
			(left_nothing && left_edge_is_world && right_slight_positive_slope && look_left) || \
			(left_nothing && left_edge_is_world && right_slight_negative_slope && look_right) || \
			(left_slight_negative_slope && right_edge_is_world && right_nothing && look_right) || \
			(left_slight_positive_slope && right_edge_is_world && right_nothing && look_left) || \
			(left_walkable_negative_slope && right_slight_positive_slope && look_left && !valley_left) || \
			(left_slight_negative_slope && right_walkable_positive_slope && look_right && !valley_right) || \
			(left_walkable_positive_slope && right_slight_negative_slope && look_left && slight_slope_peak_right && !slight_slope_peak_left) || \
			(left_slight_positive_slope && right_walkable_negative_slope && look_right && slight_slope_peak_left && !slight_slope_peak_right), #2 for downslope into air #2 for downslope from air #2 for valley 2 for peak
		"up_slope":
			(left_negative_slope && right_negative_slope && look_left) || \
			(left_positive_slope && right_positive_slope && look_right) || \
			(left_nothing && left_edge_is_world && right_negative_slope && look_left) || \
			(left_positive_slope && right_edge_is_world && right_nothing && look_right) || \
			(left_negative_slope && right_edge_is_world && right_nothing && look_left) || \
			(right_positive_slope && left_edge_is_world && left_nothing && look_right) || \
			(left_negative_slope && right_walkable_positive_slope && look_left && !valley_right) || \
			(left_walkable_negative_slope && right_positive_slope && look_right && !valley_left) || \
			(left_walkable_positive_slope && right_negative_slope && look_left && peak_left) || \
			(left_positive_slope && right_walkable_negative_slope && look_right && peak_right), #2 for upslope into air #2 for upslope from air #2 for valley 2 for peak
		"down_slope":
			(left_positive_slope && right_positive_slope && look_left) || \
			(left_negative_slope && right_negative_slope && look_right) || \
			(left_nothing && left_edge_is_world && right_positive_slope && look_left) || \
			(left_negative_slope && right_edge_is_world && right_nothing && look_right) || \
			(left_negative_slope && right_edge_is_world && right_nothing && look_right) || \
			(left_positive_slope && right_edge_is_world && right_nothing && look_left) || \
			(left_walkable_negative_slope && right_positive_slope && look_left && !valley_left) || \
			(left_negative_slope && right_walkable_positive_slope && look_right && !valley_right) || \
			(left_walkable_positive_slope && right_negative_slope && look_left && peak_right) || \
			(left_positive_slope && right_walkable_negative_slope && look_right && peak_left), #2 for downslope into air #2 downwslope from air #2 for valley 2 for peak
		"up_slope_to_stand":
			((left_no_slope && right_walkable_negative_slope && look_left && !edge_right) || \
			(left_walkable_positive_slope && right_no_slope && look_right && !edge_left)),
		"stand_to_up_slope":
			((left_walkable_negative_slope && right_no_slope && look_left && !absolute_right) || \
			(left_no_slope  && right_walkable_positive_slope && look_right && !absolute_left)),
		"stand_to_down_slope":
			((left_walkable_positive_slope && right_no_slope && look_left && !edge_left) || \
			(left_no_slope && right_walkable_negative_slope && look_right && !edge_right)),
		"down_slope_to_stand":
			((left_no_slope && right_walkable_positive_slope && look_left && !absolute_left) || \
			(left_walkable_negative_slope && right_no_slope && look_right && !absolute_right)),
		"peak":
			left_walkable_positive_slope && right_walkable_negative_slope && ((!peak_left && !peak_right) || (peak_left && peak_right )) && (!slight_slope_peak_left && !slight_slope_peak_right || slight_slope_peak_left && slight_slope_peak_right),
		"valley":
			left_walkable_negative_slope && right_walkable_positive_slope && valley_left && valley_right
	}

	var special_transition_conditions = {
		"stand_to_up_slope":
			(left_negative_slope && right_no_slope && look_left && !absolute_right) || \
			(left_no_slope  && right_positive_slope && look_right && !absolute_left),
		"stand_to_slight_up_slope":
			(left_slight_negative_slope && right_no_slope && look_left && !absolute_right) || \
			(left_no_slope  && right_slight_positive_slope && look_right && !absolute_left),
		"down_slope_to_stand":
			(left_no_slope && right_positive_slope && look_left && !absolute_left) || \
			(left_negative_slope && right_no_slope && look_right && !absolute_right),
		"slight_down_slope_to_stand":
			(left_no_slope && right_slight_positive_slope && look_left && !absolute_left) || \
			(left_slight_negative_slope && right_no_slope && look_right && !absolute_right),
		"up_slope_to_stand":
			(left_no_slope && right_negative_slope && look_left && !edge_right) || \
			(left_positive_slope && right_no_slope && look_right && !edge_left),
		"slight_up_slope_to_stand":
			(left_no_slope && right_slight_negative_slope && look_left && !edge_right) || \
			(left_slight_positive_slope && right_no_slope && look_right && !edge_left),
		"stand_to_down_slope":
			(left_positive_slope && right_no_slope && look_left && !edge_left) || \
			(left_no_slope && right_negative_slope && look_right && !edge_right),
		"stand_to_slight_down_slope":
			(left_slight_positive_slope && right_no_slope && look_left && !edge_left) || \
			(left_no_slope && right_slight_negative_slope && look_right && !edge_right),

		"up_slope_to_peak":
			(left_walkable_positive_slope && right_negative_slope && look_left && peak_left) || \
			(left_positive_slope && right_walkable_negative_slope && look_right && peak_right),
		"slight_up_slope_to_peak":
			(left_walkable_positive_slope && right_slight_negative_slope && look_left && slight_slope_peak_left && !slight_slope_peak_right) || \
			(left_slight_positive_slope && right_walkable_negative_slope && look_right && slight_slope_peak_right && !slight_slope_peak_left),
		"peak_to_down_slope":
			(left_walkable_positive_slope && right_negative_slope && look_left && peak_right) || \
			(left_positive_slope && right_walkable_negative_slope && look_right && peak_left),
		"peak_to_slight_down_slope":
			(left_walkable_positive_slope && right_slight_negative_slope && look_left && slight_slope_peak_right && !slight_slope_peak_left) || \
			(left_slight_positive_slope && right_walkable_negative_slope && look_right && slight_slope_peak_left && !slight_slope_peak_right),

		"valley_to_up_slope":
			(left_negative_slope && right_walkable_positive_slope && look_left && !valley_right) || \
			(left_walkable_negative_slope && right_positive_slope && look_right && !valley_left),
		"valley_to_slight_up_slope":
			(left_slight_negative_slope && right_walkable_positive_slope && look_left && !valley_right) || \
			(left_walkable_negative_slope && right_slight_positive_slope && look_right && !valley_left),
		"down_slope_to_valley":
			(left_walkable_negative_slope && right_positive_slope && look_left && !valley_left) || \
			(left_negative_slope && right_walkable_positive_slope && look_right && !valley_right),
		"slight_down_slope_to_valley":
			(left_walkable_negative_slope && right_slight_positive_slope && look_left && !valley_left) || \
			(left_slight_negative_slope && right_walkable_positive_slope && look_right && !valley_right),

		#"up_slope_on_edge":
			#(left_nothing && left_edge_is_slope && right_negative_slope && look_left) || \
			#(left_positive_slope && right_edge_is_slope && right_nothing && look_right),
		#"up_slope_on_edge_front":
			#(left_negative_slope && right_edge_is_slope && right_nothing && look_left) || \
			#(right_positive_slope && left_edge_is_slope && left_nothing && look_right),
		"edge_on_any_up_slope":
			(!left_edge_is_world && right_walkable_negative_slope && look_left) || \
			(left_walkable_positive_slope && !right_edge_is_world && look_right),
		"edge_front_or_turn_on_any_down_slope":
			(left_walkable_positive_slope && !right_edge_is_world && look_left) || \
			(!left_edge_is_world && right_walkable_negative_slope && look_right),

	}

	#slope crouch prevention
	if conditions["slight_up_slope"] or conditions["slight_down_slope"] or conditions["up_slope"] or conditions["down_slope"]:
		pc.forbid_crouching = true
	else: pc.forbid_crouching = false

	match ap.current_animation: #do not use elif here
		"edge":
			next_animations = check_and_append_animations(["edge", "edge_front", "edge_turn", "stand_close", "up_slope", "down_slope", "slight_up_slope", "slight_down_slope"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				next_animations = check_and_append_moving_animations(next_animations)

		"edge_front":
			next_animations = check_and_append_animations(["edge", "stand_close", "stand_close_reverse", "up_slope", "down_slope", "slight_up_slope", "slight_down_slope"], conditions, next_animations)
			if conditions["edge_turn"] or conditions["edge_front"]:
				next_animations.append("edge_front")
			if stand_close_left and stand_close_right and !pc.is_crouching: #exception to condition
				next_animations.append("stand")
			if stand_close_left and stand_close_right and pc.is_crouching: #exception to condition
				next_animations.append("crouch")
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				next_animations = check_and_append_moving_animations(next_animations)

		"edge_turn":
			next_animations = check_and_append_animations(["edge", "stand_close", "stand_close_reverse", "up_slope", "down_slope", "slight_up_slope", "slight_down_slope"], conditions, next_animations)
			if conditions["edge_turn"] or conditions["edge_front"]:
				next_animations.append("edge_turn")
			if stand_close_left and stand_close_right and !pc.is_crouching: #exception to condition
				next_animations.append("stand")
			if stand_close_left and stand_close_right and pc.is_crouching: #exception to condition
				next_animations.append("crouch")
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				next_animations = check_and_append_moving_animations(next_animations)

		"stand":
			next_animations = check_and_append_animations(["stand_close", "stand_close_reverse", "up_slope_to_stand", "stand_to_up_slope", "stand_to_down_slope", "down_slope_to_stand"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case... add room for velocity
				if push_left_wall or push_right_wall:
					next_animations.append("push")
				else:
					next_animations = check_and_append_moving_animations(next_animations)
			elif pc.move_dir.x == 0.0 and next_animations == []: #last case number 2
				if pc.is_crouching:
					next_animations.append("crouch")
				else:
					next_animations.append("stand")

		"crouch":
			next_animations = check_and_append_animations(["stand_close"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case... add room for velocity
				if push_left_wall or push_right_wall:
					next_animations.append("push")
				else:
					next_animations = check_and_append_moving_animations(next_animations)
			elif pc.move_dir.x == 0.0 and next_animations == []: #last case number 2
				if pc.is_crouching:
					next_animations.append("crouch")
				else:
					next_animations.append("stand")

		"push":
			if pc.move_dir.x == 0.0: #not moving
				if !pc.is_crouching:
					next_animations.append("stand")
				else:
					next_animations.append("crouch")
			elif !push_left_wall and !push_right_wall:
				next_animations = check_and_append_moving_animations(next_animations)


		"run":
			next_animations = run_tree(conditions)

		"back_run":
			next_animations = run_tree(conditions)

		"crouch_run":
			next_animations = run_tree(conditions)



		"stand_close":
			next_animations = check_and_append_animations(["stand", "stand_close", "edge", "edge_front", "edge_turn", "stand_to_down_slope"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				next_animations = check_and_append_moving_animations(next_animations)
			elif pc.move_dir.x == 0.0 and next_animations == []: #last case number 2
				if pc.is_crouching:
					next_animations.append("crouch")
				else:
					next_animations.append("stand_close")

		"stand_close_reverse":
			next_animations = check_and_append_animations(["stand", "stand_close_reverse", "edge", "edge_front", "edge_turn", "up_slope_to_stand"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				next_animations = check_and_append_moving_animations(next_animations)
			elif pc.move_dir.x == 0.0 and next_animations == []: #last case number 2
				if pc.is_crouching:
					next_animations.append("crouch")
				else:
					next_animations.append("stand_close_reverse")


		"slight_up_slope":
			next_animations = check_and_append_animations(["edge", "edge_front", "edge_turn", "up_slope_to_stand", "stand_to_up_slope", "peak", "valley"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				if push_left_wall or push_right_wall:
					next_animations.append("slight_up_push")
				else:
					next_animations = check_and_append_moving_animations(next_animations)

		"slight_down_slope":
			next_animations = check_and_append_animations(["edge", "edge_front", "edge_turn", "stand_to_down_slope", "down_slope_to_stand", "peak", "valley"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				if push_left_wall or push_right_wall:
					next_animations.append("slight_down_push")
				else:
					next_animations = check_and_append_moving_animations(next_animations)

		"up_slope":
			next_animations = check_and_append_animations(["edge", "edge_front", "edge_turn", "up_slope_to_stand", "stand_to_up_slope", "peak", "valley"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				if push_left_wall or push_right_wall:
					next_animations.append("up_push")
				else:
					next_animations = check_and_append_moving_animations(next_animations)

		"down_slope":
			next_animations = check_and_append_animations(["edge", "edge_front", "edge_turn", "stand_to_down_slope", "down_slope_to_stand", "peak", "valley"], conditions, next_animations)
			if pc.move_dir.x != 0.0 and next_animations == []: #last case
				if push_left_wall or push_right_wall:
					next_animations.append("down_push")
				else:
					next_animations = check_and_append_moving_animations(next_animations)

		"up_slope_to_stand":
			if pc.move_dir.x == 0.0: next_animations = check_and_append_animations(["stand", "stand_close_reverse", "up_slope_to_stand", "slight_up_slope", "up_slope"], conditions, next_animations)
			else: next_animations = check_and_append_moving_animations(next_animations)

		"stand_to_up_slope":
			if pc.move_dir.x == 0.0: next_animations = check_and_append_animations(["stand", "stand_to_up_slope", "slight_up_slope", "up_slope"], conditions, next_animations)
			else: next_animations = check_and_append_moving_animations(next_animations)

		"stand_to_down_slope":
			if pc.move_dir.x == 0.0: next_animations = check_and_append_animations(["stand", "stand_close", "stand_to_down_slope", "slight_down_slope", "down_slope"], conditions, next_animations)
			else: next_animations = check_and_append_moving_animations(next_animations)

		"down_slope_to_stand":
			if pc.move_dir.x == 0.0: next_animations = check_and_append_animations(["stand", "down_slope_to_stand", "slight_down_slope", "down_slope"], conditions, next_animations)
			else: next_animations = check_and_append_moving_animations(next_animations)

		"peak":
			if pc.move_dir.x == 0.0: next_animations = check_and_append_animations(["slight_up_slope", "up_slope", "slight_down_slope", "down_slope"], conditions, next_animations)
			else: next_animations = check_and_append_moving_animations(next_animations)

		"valley":
			if pc.move_dir.x == 0.0: next_animations = check_and_append_animations(["slight_up_slope", "up_slope", "slight_down_slope", "down_slope"], conditions, next_animations)
			else: next_animations = check_and_append_moving_animations(next_animations)



		"slight_up_push":
			if pc.move_dir.x == 0.0: #not moving
				next_animations.append("slight_up_slope")
			elif !push_left_wall and !push_right_wall:
				next_animations = check_and_append_moving_animations(next_animations)

		"slight_down_push":
			if pc.move_dir.x == 0.0: #not moving
				next_animations.append("slight_down_slope")
			elif !push_left_wall and !push_right_wall:
				next_animations = check_and_append_moving_animations(next_animations)

		"up_push":
			if pc.move_dir.x == 0.0: #not moving
				next_animations.append("up_slope")
			elif !push_left_wall and !push_right_wall:
				next_animations = check_and_append_moving_animations(next_animations)

		"down_push":
			if pc.move_dir.x == 0.0: #not moving
				next_animations.append("down_slope")
			elif !push_left_wall and !push_right_wall:
				next_animations = check_and_append_moving_animations(next_animations)


	if next_animations.is_empty():
		play_animation(ap.current_animation)
		if ap.current_animation == "edge":
			do_edge_turn = true
		else:
			do_edge_turn = false

		check_if_offset(ap.current_animation, conditions, special_transition_conditions, delta)
		return

	if next_animations.size() != 1:
		printerr("ERROR: CONFLICT SETTING RUN ANIMATION FROM ", ap.current_animation, " to ", next_animations)
		return
	#if next_animations[0] == ap.current_animation:
		#return

	if next_animations[0] == "edge":
		do_edge_turn = true
	else:
		do_edge_turn = false

	check_if_offset(next_animations[0], conditions, special_transition_conditions, delta)
	play_animation(next_animations[0])

	#saved_move_dir = pc.move_dir #for 2 frame stand

### ANIMATION TREES ###

func run_tree(conditions) -> Array:
	var out = []
	if pc.move_dir.x == 0.0: #not moving
		out = check_and_append_animations(["edge", "edge_front", "edge_turn", "stand", "crouch", "stand_close", "stand_close_reverse", \
		"slight_up_slope", "slight_down_slope", "up_slope", "down_slope", "up_slope_to_stand", "stand_to_up_slope", "stand_to_down_slope", "down_slope_to_stand", \
		"peak", "valley"], conditions, out)
	else:
		if push_left_wall or push_right_wall:
			if conditions["slight_up_slope"]:
				out.append("slight_up_push")
			elif conditions["slight_down_slope"]:
				out.append("slight_down_push")
			elif conditions["up_slope"]:
				out.append("up_push")
			elif conditions["down_slope"]:
				out.append("down_push")
			else:
				out.append("push")
		else:
			out = check_and_append_moving_animations(out)
	return out

func check_and_append_animations(animations: Array, conditions: Dictionary, next_animations: Array) -> Array: #only works if condition has same name as animation
	var out = next_animations
	for a in animations:
		if conditions[a]:
			out.append(a)
	return out

func check_and_append_moving_animations(next_animations: Array) -> Array:
	var out = next_animations
	if pc.is_crouching:
		out.append("crouch_run")
	elif sign(pc.look_dir.x) != sign(pc.move_dir.x):
		out.append("back_run")
	else:
		out.append("run")
	return out


func check_if_offset(animation, conditions, special_transition_conditions, delta):
	if animation == "run" or animation == "back_run":
		var is_slight_slope = conditions["slight_up_slope"] or conditions["slight_down_slope"]
		var is_slope = conditions["up_slope"] or conditions["down_slope"]
		do_run_animation_offset(is_slight_slope, is_slope, delta)
	else:
		sprite.gun_pos_offset = Vector2.ZERO
		do_animation_sprite_offset(animation, special_transition_conditions, delta)

func do_animation_sprite_offset(animation, special_transition_conditions, delta):
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
	}

	var special_transition_offsets = {
		"stand_to_up_slope": [Vector2(3, 0), Vector2(0, 7)],
		"stand_to_slight_up_slope": [Vector2(4, 1), Vector2(0, 3)],
		"down_slope_to_stand": [Vector2(0, 7), Vector2(-2, 2)],
		"slight_down_slope_to_stand": [Vector2(0, 5), Vector2(-2, 2)],
		"up_slope_to_stand": [Vector2(0, 9), Vector2(0, 2)],
		"slight_up_slope_to_stand": [Vector2(0, 5), Vector2(0, 2)],
		"stand_to_down_slope": [Vector2(0, 4), Vector2(0, 7)],
		"stand_to_slight_down_slope": [Vector2(0, 4), Vector2(0, 7)],

		"up_slope_to_peak": [Vector2(0, 9), Vector2(0, 5)],
		"slight_up_slope_to_peak": [Vector2(0, 4), Vector2(0, 2)],
		"peak_to_down_slope": [Vector2(0, 3), Vector2(0, 7)],
		"peak_to_slight_down_slope": [Vector2(0, 2), Vector2(0, 4)],

		"valley_to_up_slope": [Vector2(0, 9), Vector2(2, 7)],
		"valley_to_slight_up_slope": [Vector2(0, 4), Vector2(0, 4)],
		"down_slope_to_valley": [Vector2(-2, 5), Vector2(0, 7)],
		"slight_down_slope_to_valley": [Vector2(0, 4), Vector2(0, 4)],

		#"up_slope_on_edge": [Vector2(0, 7), Vector2(0, 0)],
		#"up_slope_on_edge_front": [Vector2(0, 0), Vector2(0, 0)],
		"edge_on_any_up_slope": [Vector2(0, 0), Vector2(0, 7)],
		"edge_front_or_turn_on_any_down_slope": [Vector2(0, 0), Vector2(0, 5)]
	}



	var do_special_transition = false
	for c in special_transition_conditions:
		if special_transition_conditions[c]: do_special_transition = true

	#special conditions
	if do_special_transition:
		for c in special_transition_conditions: #warning, this has no protection for if there are multiple of these triggered
			if special_transition_conditions[c]:
				var t
				var gun_extra_offset = Vector2.ZERO
				match c:
					"stand_to_up_slope":
						t = calc_lerp_delta_center(0.5, 6.5)
						gun_extra_offset = Vector2(0, 16)
					"stand_to_slight_up_slope":
						t = calc_lerp_delta_center(1.0, 3.5)
						gun_extra_offset = Vector2(0, 16)
					"down_slope_to_stand":
						t = calc_lerp_delta_center(6.5, 1.0)
						gun_extra_offset = Vector2(0, 16)
					"slight_down_slope_to_stand":
						t = calc_lerp_delta_center(3.5, 1.0)
						gun_extra_offset = Vector2(0, 16)
					"up_slope_to_stand":
						t = calc_lerp_delta_center(6.5, 0.5)
						gun_extra_offset = Vector2(0, 16)
					"slight_up_slope_to_stand":
						t = calc_lerp_delta_center(3.5, 0.5)
						gun_extra_offset = Vector2(0, 16)
					"stand_to_down_slope":
						t = calc_lerp_delta_center(0.5, 3.5)
						gun_extra_offset = Vector2(0, 16)
					"stand_to_slight_down_slope":
						t = calc_lerp_delta_center(0.5, 6.5)
						gun_extra_offset = Vector2(0, 16)

					"up_slope_to_peak":
						t = calc_lerp_delta_center(6.5, 2.0)
						gun_extra_offset = Vector2(0, 7)
					"slight_up_slope_to_peak":
						t = calc_lerp_delta_center(3.5, 2.0)
						gun_extra_offset = Vector2(0, 12)
					"peak_to_down_slope":
						t = calc_lerp_delta_center(2.0, 6.5)
						gun_extra_offset = Vector2(0, 9)
					"peak_to_slight_down_slope":
						t = calc_lerp_delta_center(1.5, 3.5)
						gun_extra_offset = Vector2(0, 12)

					"valley_to_up_slope":
						t = calc_lerp_delta_side(Vector2(pc.look_dir.x, 0), 12.5, 3.0)
						gun_extra_offset = Vector2(0, 7)
					"valley_to_slight_up_slope":
						t = calc_lerp_delta_side(Vector2(pc.look_dir.x, 0), 6.5, 3.0)
						gun_extra_offset = Vector2(0, 12)
					"down_slope_to_valley":
						t = calc_lerp_delta_side(Vector2(pc.look_dir.x * -1.0, 0), 3.0, 6.5)
						gun_extra_offset = Vector2(0, 9)
					"slight_down_slope_to_valley":
						t = calc_lerp_delta_side(Vector2(pc.look_dir.x * -1.0, 0), 3, 12.5)
						gun_extra_offset = Vector2(0, 12)

					#"up_slope_on_edge":
						#print("over_edge")
						#t = calc_slope_to_peak_lerp_delta()
						#gun_extra_offset = Vector2(0, 9)
					#"up_slope_on_edge_front":
						#print("over_edge_front")
						#t = calc_slope_to_peak_lerp_delta()
						#gun_extra_offset = Vector2(0, 9)
					"edge_on_any_up_slope":
						t = calc_edge_on_any_slope_lerp_delta(Vector2(pc.look_dir.x, 0))
						gun_extra_offset = Vector2(0, 16)
					"edge_front_or_turn_on_any_down_slope":
						t = calc_edge_front_or_turn_on_any_slope_lerp_delta(Vector2(pc.look_dir.x, 0))
						gun_extra_offset = Vector2(0, 16)

				var p0 = Vector2(special_transition_offsets[c][0].x * pc.look_dir.x, special_transition_offsets[c][0].y)
				var p1 = Vector2(special_transition_offsets[c][1].x * pc.look_dir.x, special_transition_offsets[c][1].y)
				var translation = p0.lerp(p1, t) #interpolated
				var final_position = Vector2(0, -16) + translation
				#var speed = 30.0
				sprite.position = final_position #sprite.position.lerp(final_position, delta * speed)
				sprite.gun_pos_offset = sprite.position + gun_extra_offset


	#normal conditions
	elif offsets.has(animation): #only works if these lerp animations can't become eachother as we never reset sprite.position
		#if offsets[animation] is Array: #never an array!
			#var t
			#var p0 = Vector2(offsets[animation][0].x * pc.look_dir.x, offsets[animation][0].y)
			#var p1 = Vector2(offsets[animation][1].x * pc.look_dir.x, offsets[animation][1].y)
			#var translation = p0.lerp(p1, t) #interpolated
			#var final_position = Vector2(0, -16) + translation
			##var speed = 30.0
			#sprite.position = final_position# sprite.position.lerp(final_position, delta * speed)
			#sprite.gun_pos_offset = sprite.position - Vector2(0, -16)
		#else:
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



func calc_lerp_delta_center(d1: float, d2: float) -> float:
	var out = 0.0
	var par = pc.get_node("LerpDeltaVertical")
	var distance = par.get_collision_point().y - par.global_position.y
	#print(distance)
	out = clampf(remap(distance, d1, d2, 0.0, 1.0), 0.0, 1.0)
	#print(out)
	return out

func calc_lerp_delta_side(direction, d1: float, d2: float) -> float:
	var out = 0.0
	var par
	if direction == Vector2.LEFT: par = pc.get_node("LerpDeltaVerticalRight")
	if direction == Vector2.RIGHT: par = pc.get_node("LerpDeltaVerticalLeft")
	var distance = par.get_collision_point().y - par.global_position.y
	#print(distance)
	out = clampf(remap(distance, d1, d2, 0.0, 1.0), 0.0, 1.0)
	#print(out)
	return out


func calc_edge_on_any_slope_lerp_delta(direction) -> float:
	var out = 0.0
	var par
	if direction == Vector2.LEFT: par = pc.get_node("LerpDeltaVerticalRight")
	if direction == Vector2.RIGHT: par = pc.get_node("LerpDeltaVerticalLeft")
	var distance = par.get_collision_point().y - par.global_position.y
	out = clampf(remap(distance, 0.5, 7.5, 0.0, 1.0), 0.0, 1.0)
	return out

func calc_edge_front_or_turn_on_any_slope_lerp_delta(direction) -> float:
	var out = 0.0
	var par
	if direction == Vector2.LEFT: par = pc.get_node("LerpDeltaVerticalLeft")
	if direction == Vector2.RIGHT: par = pc.get_node("LerpDeltaVerticalRight")
	var distance = par.get_collision_point().y - par.global_position.y
	out = clampf(remap(distance, 0.5, 7.5, 0.0, 1.0), 0.0, 1.0)
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
	var stand_group = ["edge_turn", "stand", "crouch", "stand_close", "stand_close_reverse", "slight_up_slope", "slight_down_slope", "up_slope", "down_slope", "up_slope_to_stand", "stand_to_up_slope", "stand_to_down_slope", "down_slope_to_stnad", "peak", "valley", "push", "slight_up_push", "slight_down_push", "up_push", "down_push"]

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
		#cap max_speed by how hard you pressed your analog stick in X axis
		if abs(pc.move_dir.x) <= inp.Xaxis_clampzone: #makes inputs close to 1.0 equal to 1.0, analog otherwise
			max_speed *= abs(pc.move_dir.x)

		if pc.is_crouching:
			max_speed = mm.crouch_speed

		if sign(pc.move_dir.x) != sign(out.x):
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
	pc.floor_snap_length = 7.9
	pc.floor_max_angle = 0.8 #well over 45degrees so we can have a lower safe_margin
	pc.safe_margin = 0.008 #may cause issues this low
	do_edge_turn = false
	play_animation("run")
func exit():
	sprite.position = Vector2i(0.0, -16.0)
	sprite.gun_pos_offset = Vector2i(0.0, 0.0)
	is_dropping = false
	pc.forbid_crouching = false
