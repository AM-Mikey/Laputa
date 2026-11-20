extends PhysicsProp

## Pushable, indestructible minecart.
## - Player pushes it by walking into its side while on the floor (not while riding on top).
## - Builds up speed slowly, then rolls on with inertia and slows down from ground friction.
## - Keeps its horizontal momentum when it rolls off a ledge (if allowed).
## - Crushes players/enemies it falls onto.
## - Armor layer: bullets never pass through it, and nudge it based on their knockback_strength.
## - Pushed by PhysFan wind. Water gravity comes from the Water Area2D's gravity override.

const ICON = preload("res://assets/Prop/MinecartIcon.png")

signal blocked(bullet, body) #emitted by Bullet.armor_check()

@export var can_fall_off_ledges := true
@export var crush_players := true
@export var crush_enemies := true

@export_group("Push")
@export var push_max_speed := 70.0 #keep below player walk speed (90) so the player stays in contact
@export var push_start_accel := 40.0 #accel when starting from rest, feels heavy
@export var push_full_accel := 140.0 #accel once rolling
@export var ground_friction := 90.0 #decel when nothing is pushing, controls how far it coasts
@export var push_reach := 2.0 #px gap between player and cart that still counts as touching
@export var push_grace_time := 0.12 #keeps the push going through the player's contact stutter

@export_group("Shot")
@export var shot_push_scale := 2.0 #velocity added = bullet knockback_strength * this

@export_group("Wind")
@export var wind_force_scale := 60.0 #PhysWindColumn speed -> px/s^2, matches the player (speed 4 ~= gravity)
@export var max_wind_speed := 120.0

@export_group("Crush")
@export var crush_min_fall_speed := 40.0
@export var thud_min_fall_speed := 80.0

var block_dir := Vector2.ZERO #armor on all sides, read by Bullet.armor_check()
var crush_targets := []
var push_dir := 0
var push_grace := 0.0
var pending_shot_velocity := 0.0
var is_grounded := true
var last_fall_speed := 0.0

@onready var ground_left: RayCast2D = $GroundLeft
@onready var ground_right: RayCast2D = $GroundRight


func setup():
	is_wind_affected = true
	blocked.connect(_on_blocked)
	w.emit_signal("finished_spawn_entities_step")


func _physics_process(delta):
	_update_push(delta)
	_update_crush()


func _integrate_forces(state: PhysicsDirectBodyState2D):
	var step := state.step
	var vel := state.linear_velocity
	var was_grounded := is_grounded
	is_grounded = ground_left.is_colliding() || ground_right.is_colliding()

	#landing
	if is_grounded && !was_grounded && last_fall_speed >= thud_min_fall_speed:
		am.play("block_thud", self)
	last_fall_speed = max(vel.y, 0.0)

	#shots
	vel.x += pending_shot_velocity
	pending_shot_velocity = 0.0

	#wind
	var wind_x := 0.0
	for area in _get_strongest_winds():
		if is_grounded && area.wind_dir.y > 0.0: continue
		var accel: Vector2 = area.wind_dir * area.speed * wind_force_scale * step
		vel.y += accel.y
		wind_x += accel.x
	if wind_x != 0.0:
		if abs(vel.x) < max_wind_speed || sign(vel.x) != sign(wind_x):
			vel.x = clampf(vel.x + wind_x, -max_wind_speed, max_wind_speed)

	#push / friction (only on the ground, in the air it keeps its momentum)
	if is_grounded:
		var pushing_faster: bool = push_dir != 0 && (sign(vel.x) != push_dir || abs(vel.x) < push_max_speed)
		if pushing_faster:
			var t := clampf(abs(vel.x) / push_max_speed, 0.0, 1.0)
			var accel := lerpf(push_start_accel, push_full_accel, t)
			vel.x = move_toward(vel.x, push_dir * push_max_speed, accel * step)
		else: #wind still has to overcome friction, so weak wind can't budge it
			vel.x = move_toward(vel.x, 0.0, ground_friction * step)

		if !can_fall_off_ledges:
			if vel.x > 0.0 && !ground_right.is_colliding():
				vel.x = 0.0
			elif vel.x < 0.0 && !ground_left.is_colliding():
				vel.x = 0.0

	state.linear_velocity = vel


### PUSHING ###

func _update_push(delta):
	var dir := _get_player_push_dir()
	if dir != 0:
		push_dir = dir
		push_grace = push_grace_time
	else:
		push_grace -= delta
		if push_grace <= 0.0:
			push_dir = 0


func _get_player_push_dir() -> int:
	var pc = f.pc()
	if !pc || pc.disabled || !pc.is_on_floor(): return 0
	var mm = pc.get_node("MovementManager")
	if mm.current_state != mm.states["run"]: return 0

	var rect := _get_rect()
	var pc_half_width := 6.0
	var pc_feet: float = pc.global_position.y
	var pc_head: float = pc_feet - 15.0
	#must be beside the cart, not riding on top of it
	if pc_feet <= rect.position.y + 1.0 || pc_head >= rect.end.y: return 0

	if pc.move_dir.x > 0.0:
		var gap: float = rect.position.x - (pc.global_position.x + pc_half_width)
		if gap >= -1.0 && gap <= push_reach: return 1
	elif pc.move_dir.x < 0.0:
		var gap: float = (pc.global_position.x - pc_half_width) - rect.end.x
		if gap >= -1.0 && gap <= push_reach: return -1
	return 0


func _get_rect() -> Rect2:
	var shape: RectangleShape2D = $CollisionShape2D.shape
	return Rect2($CollisionShape2D.global_position - shape.size / 2.0, shape.size)


### SHOTS ###

func bullet_push(bullet):
	pending_shot_velocity += bullet.direction.x * bullet.knockback_strength * shot_push_scale

func _on_blocked(bullet, _body):
	bullet_push(bullet)


### WIND ###

func _get_strongest_winds() -> Array:
	var strongest_by_dir := {}
	for area in wind_areas_inside:
		var key: Vector2 = area.wind_dir
		if not strongest_by_dir.has(key) or area.speed > strongest_by_dir[key].speed:
			strongest_by_dir[key] = area
	return strongest_by_dir.values()


### CRUSHING ###

func _update_crush():
	if crush_targets.is_empty() || linear_velocity.y < crush_min_fall_speed: return
	for t in crush_targets.duplicate():
		crush(t[0], t[1])
		crush_targets.erase(t)


func crush(type, target):
	if !is_instance_valid(target): return
	match type:
		"player":
			if crush_players:
				f.pc().invincible = false
				target.hit(999, Vector2.ZERO, $CrushDetector)
		"enemy":
			if crush_enemies:
				target.hit(999, Vector2.ZERO, $CrushDetector)


func _get_crush_target(body):
	if body.get_collision_layer_value(1):
		return ["player", body.get_parent()]
	elif body.get_collision_layer_value(2):
		return ["enemy", body]
	return null


### SIGNALS ###

func _on_CrushDetector_body_entered(body):
	var target = _get_crush_target(body)
	if target && !crush_targets.has(target):
		crush_targets.append(target)

func _on_CrushDetector_body_exited(body):
	var target = _get_crush_target(body)
	if target:
		crush_targets.erase(target)
