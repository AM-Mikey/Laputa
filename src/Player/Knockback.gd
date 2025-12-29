extends Node


@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var mm = pc.get_node("MovementManager")

func state_process(_delta):
	set_move_dir()
	if mm.knockback_velocity == Vector2.ZERO:
		mm.knockback_velocity = Vector2(mm.knockback_speed.x * mm.knockback_direction.x, mm.knockback_speed.y * -1)
		pc.velocity.y = mm.knockback_velocity.y #set knockback y to this ONCE

	pc.velocity.x += mm.knockback_velocity.x
	pc.velocity.x = min(abs(pc.velocity.x), mm.speed.x) * sign(pc.velocity.x)
	mm.knockback_velocity.x *= 0.5 #next frame it falls off

	if abs(mm.knockback_velocity.x) < 1:
		mm.knockback_velocity = Vector2.ZERO
		#pc.knockback = false
		#print("changing from kb to cached")
		mm.change_state(mm.cached_state.name.to_lower())
		return

	pc.velocity = get_move_velocity(pc.velocity, pc.move_dir)
	pc.move_and_slide()
	var new_velocity = pc.velocity

	if pc.is_on_wall():
		new_velocity.y = max(pc.velocity.y, new_velocity.y)

	pc.velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap

func set_move_dir():
	var move_dir = Vector2.ZERO
	if pc.can_input:
		move_dir= Vector2(Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 0.0)
		if not mm.coyote_timer.is_stopped() and Input.is_action_just_pressed("jump"):
			move_dir = Vector2(move_dir.x, -1.0)
	pc.move_dir = move_dir



### GETTERS ###

func get_move_velocity(velocity, move_dir):
	var out = velocity
	#Y
	out.y += mm.gravity * get_physics_process_delta_time()
	if sign(move_dir.y) == -1:
		out.y = mm.speed.y * pc.move_dir.y
	#X
	if move_dir.x != 0.0:
		out.x = min(abs(out.x) + mm.acceleration, mm.speed.x)
		out.x *= pc.move_dir.x
	return out



### STATES ###

func enter(_prev_state: String) -> void:
	var disable = [
		pc.get_node("CollisionShape2D"),
		pc.get_node("CrouchingCollision")]
	var enable = [
		pc.get_node("JumpCollision"),
		pc.get_node("SSPDetector/CollisionShape2D2")]
	mm.disable_collision_shapes(disable)
	mm.enable_collision_shapes(enable)

	pc.set_up_direction(mm.FLOOR_NORMAL)
	pc.set_floor_stop_on_slope_enabled(true)

func exit(_next_state: String) -> void:
	var disable = [
		pc.get_node("CrouchingCollision"),
		pc.get_node("JumpCollision"),
		pc.get_node("SSPDetector/CollisionShape2D2")]
	var enable = [pc.get_node("CollisionShape2D")]
	mm.disable_collision_shapes(disable)
	mm.enable_collision_shapes(enable)
