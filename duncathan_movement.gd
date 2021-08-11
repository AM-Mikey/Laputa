class_name Movement
extends Node2D

signal movement_state_changed(previous, new)
signal facing_changed(previous, new)

enum State {
	IDLE,
	RUNNING,
	JUMPING,
	FALLING,
	HITSTUN,
	DEATH,
	
	FLYING
}

# PhysicsAttributes
# @TODO: update once https://github.com/godotengine/godot/pull/32018 is merged to a stable branch
#export(PhysicsAttributes) var Physics: PhysicsAttributes
export(Resource) var Physics
export(Global.HDirs) var facing = Global.HDirs.RIGHT setget set_facing

onready var Parent: Entity = get_parent()

var movement_state = State.IDLE setget set_movement_state
var snap_override = false

# ensure whatever sets these is on a lower process priority
var moveRight: float
var moveLeft: float
var beginJump: bool
var holdJump: bool
var special_jump_height := 0
var wallHold: bool setget set_wallHold
var drop: bool
var move_sign := 0 setget set_move_sign
var instant_stop := false
var freeze_movement := false
var disable_sign_change := false
var hop := false
var hop_size := 1.0

var freeze_gravity := false setget set_freeze_gravity
var freeze_facing := false
var bypass_max_speed := false

var max_run_mod := 1.0
var extra_jump_dist := 0.0

var _jumping := false
var _false_jump := false
var wall_holding := 0
var swimming := false

var _velocity := Vector2()
var _coyote_time_active := true

func _physics_process(delta):
	Parent = get_parent() # just in case node hierarchy changes for some reason
	
	if !freeze_movement and !is_vel_locked():
		_velocity = _x_velocity(_velocity, delta)
		_velocity = _y_velocity(_velocity, delta)
		_velocity = _final_movement(_velocity, delta)
		
		if movement_state == State.HITSTUN and (Parent.is_on_floor() or Parent.is_offscreen() or $Recoil.is_stopped()) and special_jump_height == 0:
			if !Parent.is_in_group("player") or !Parent.dying:
				set_movement_state(State.IDLE)
			else:
				set_movement_state(State.DEATH)
				Parent.get_node("SFX").stop()
				Parent.get_node("DeathTimer").start()
		
		if (!Parent.is_in_group("player") or !Input.is_action_pressed("game_shoot")) and !is_input_locked():
			if !freeze_facing:
				#if Parent.is_on_floor():
				if move_sign < 0:
					set_facing(Global.HDirs.LEFT)
				if move_sign > 0:
					set_facing(Global.HDirs.RIGHT)
				#else:
				#	if _velocity.x < 0:
				#		set_facing(Global.HDirs.LEFT)
				#	if _velocity.x > 0:
				#		set_facing(Global.HDirs.RIGHT)
	
func _x_velocity(velocity: Vector2, delta: float) -> Vector2:
	var grounded = is_grounded() and !beginJump
	
	# multiply by delta to convert to pixels/frame
	var accel_x = (Physics.accel_run if grounded else Physics.accel_air) * delta
	var decel_x = (Physics.decel_run if grounded else Physics.decel_air) * delta
	
	if Parent.is_in_group("player") and Parent.dying:
		decel_x *= 0.3
	
	if Parent.frozen:
		decel_x *= 0.15
	
	var max_speed = Physics.max_run_speed #(Physics.max_run_speed if grounded else Physics.jump_vel.x)
	max_speed *= move_sign * max_run_mod # analog strength of movement, if applicable
	if !grounded:
		max_speed += extra_jump_dist
	else:
		extra_jump_dist = 0
	
	velocity.x = Global.approach_value(velocity.x, max_speed, accel_x if move_sign else decel_x)
	
	if !move_sign and instant_stop:
		velocity.x = 0
		instant_stop = false
	
	if grounded and !state_priority():
		self.movement_state = State.RUNNING if move_sign else State.IDLE
	
	if !Parent.is_in_group("player") or !Parent.dying:
		if !bypass_max_speed and grounded:
			velocity.x = clamp(velocity.x, -Physics.max_run_speed, Physics.max_run_speed)
	
	return velocity
	
func _y_velocity(velocity: Vector2, delta: float) -> Vector2:
	var is_on_floor = Parent.is_on_floor()
	#is_on_floor = space_state.intersect_ray(Vector2(Parent.global_position.x + velocity.x, Parent.global_position.y), Vector2(Parent.global_position.x + velocity.x, Parent.global_position.y + 15), [self, Parent], Parent.collision_mask)
	
	if is_on_floor and not snap_override:
		velocity.y = 8
		_jumping = false
		_coyote_time_active = true
		
	if Parent.is_in_group("player"):
		Parent.get_node("Animations/Float").visible = false
	
	# need to assign this here because _jumping can be modified prior to this
	var moveJump :=  not drop and (beginJump or (_jumping and holdJump))
	
	if Parent.is_in_group("player") and is_on_floor:
		Parent.jump_takeoff_position = Vector2.ZERO
		wallHold = false
	
	# jumping
	velocity = _jump(velocity, delta)
	
	# airborne (check after jumping)
	if movement_state == State.FLYING:
		if Stats.game_data[Stats.Data.upgrades] > 0 and Parent.is_in_group("player") and holdJump:
			velocity.y = -Physics.accel_gravity / 20
			_jumping = true
			Parent.get_node("Animations/Float").visible = true
			return velocity
	if !is_on_floor:
		
		if _coyote_time_active and $Coyote.is_stopped():
			$Coyote.start()
		
		if Parent.is_in_group("player") and Parent.jump_takeoff_position == Vector2.ZERO:
			Parent.jump_takeoff_position = Parent.global_position
			
		var accel_y = Physics.accel_jump*delta
		
		if not _jumping or not moveJump or velocity.y >= 0:
			# gravity
			_jumping = false
			_false_jump = false
			if Stats.game_data[Stats.Data.upgrades] > 0 and Parent.is_in_group("player") and holdJump and movement_state == State.FALLING:
				if !freeze_gravity:
					velocity.y = Physics.accel_gravity / 10
					Parent.get_node("Animations/Float").visible = true
					return velocity
			else:
				accel_y = Physics.accel_gravity*delta
		
		if freeze_gravity:
			accel_y = 0

		if Parent.is_in_group("player") and Parent.dying:
			accel_y *= 0.5
			
		velocity.y = min(velocity.y + accel_y, -Physics.jump_vel.y * 1.5)
		
		if !state_priority():
			self.movement_state = State.JUMPING if velocity.y < 0 else State.FALLING
	return velocity
	
func _final_movement(velocity: Vector2, delta: float) -> Vector2:
	var pos = Parent.position
	var collision := Parent.move_and_collide(velocity*delta, true, true, true)
	
	if collision:
		var surface_angle := abs(collision.normal.rotated(deg2rad(90)).angle())
		# constant speed running up floor slopes
		if abs(velocity.x) > Physics.max_run_speed * 0.05 and \
				surface_angle and surface_angle < Physics.FLOOR_MAX_ANGLE:
			var slide := velocity.slide(collision.normal)
			
			# this happens when landing would make you slide down a hill opposite the direction you're moving
			if slide.x and sign(slide.x) != sign(velocity.x):
				slide *= -1 # invert to slide up the hill instead
			
			velocity = Global.vec_scale_x_to(slide, velocity.x)
			
			if surface_angle > Physics.FLOOR_FULL_SPEED_ANGLE:
				# the exact value of this magic number was determined
				# via 5 full minutes of experimental testing
				velocity *= 0.9
			
			# slightly hacky? helps prevent sliding down hills for a single frame
			if !Parent.is_on_floor():
				velocity.y = Physics.accel_gravity*delta
				
	var snap := Vector2.ZERO if snap_override or _jumping else Vector2(0, Global.TILE_SIZE*0.5)
	var new_velocity := Parent.move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, Physics.FLOOR_MAX_ANGLE)
	
	Parent.position_diff(Parent.position, pos)
	
	# prevent extreme momentum from jumping up sloped walls
	if Parent.is_on_wall():
		new_velocity.y = max(velocity.y, new_velocity.y)
		
	return new_velocity
	
func _jump(velocity: Vector2, delta: float, override_check: bool = false) -> Vector2:
	# need to assign this here because _jumping can be modified prior to this
	var moveJump := !drop and beginJump and !is_jump_locked()# or (_jumping and holdJump))
	
	if special_jump_height < 0:
		override_check = true
	
	var is_on_floor = Parent.is_on_floor()
	if is_on_floor or _coyote_time_active or swimming or override_check:
		if moveJump or override_check:
			if Parent.is_in_group("player"):
				Parent.jump_takeoff_position = Parent.global_position
			if special_jump_height == 0:
				velocity.y = Physics.jump_vel.y
				if Parent.is_in_group("player") and Parent.attached_platform:
					extra_jump_dist = Parent.attached_platform.player_jump()
					velocity.x += extra_jump_dist
			else:
				velocity.y = special_jump_height
				special_jump_height = 0
				_false_jump = true
			velocity.x = min(abs(velocity.x), Physics.jump_vel.x)*sign(velocity.x)
			_jumping = true
			_coyote_time_active = false
			
	return velocity
	
func is_grounded() -> bool:
	return Parent.is_on_floor()
	
func set_movement_state(state: int):
	if movement_state != state and state == State.HITSTUN:
		$Recoil.start()
	
	emit_signal("movement_state_changed", movement_state, state)
	movement_state = state
	
func set_facing(new: int):
	emit_signal("facing_changed", facing, new)
	facing = new

func set_wallHold(new: bool) -> void:
	wallHold = new

func set_move_sign(new: int) -> void:
	if !disable_sign_change:
		move_sign = new

func _on_Coyote_timeout():
	_coyote_time_active = false

func _on_Signlock_timeout():
	disable_sign_change = false

func is_vel_locked():
	return false
	
func is_input_locked():
	match movement_state:
		State.HITSTUN, State.DEATH:
			return true
	return false

func is_jump_locked() -> bool:
	match movement_state:
		State.FLYING, State.HITSTUN, State.DEATH:
			return true
	return false

func state_priority():
	match movement_state:
		State.HITSTUN, State.DEATH, State.FLYING:
			return true
	return false

func set_freeze_gravity(g):
	freeze_gravity = g
	if g:
		_velocity.y = 0
