extends PhysicsProp

## Pushable, indestructible minecart.
## - Player pushes it by walking into its side while on the floor (not while riding on top).
## - Builds up speed slowly, then rolls on with inertia and slows down from ground friction.
## - Keeps its horizontal momentum when it rolls off a ledge (if allowed).
## - Crushes players/enemies it falls onto.
## - Armor layer: bullets never pass through it, and nudge it based on their knockback_strength.
## - Pushed by PhysFan wind. Water gravity comes from the Water Area2D's gravity override.
## - Rides conveyor belts (and other carts): friction works relative to whatever it's standing on.
## - Carries physics props (breakblocks) on top with friction, unless something pushes them off.

const ICON = preload("res://assets/Prop/MinecartIcon.png")

signal blocked(bullet, body) #emitted by Bullet.armor_check()

@export var can_fall_off_ledges := true
@export var crush_players := true
@export var crush_enemies := true

var push_max_speed := 80.0 #keep below player walk speed (90) so the player stays in contact
var push_start_accel := 40.0 #accel when starting from rest, feels heavy
var push_full_accel := 140.0 #accel once rolling
var ground_friction := 90.0 #decel when nothing is pushing, controls how far it coasts
var push_reach := 2.0 #px gap between player and cart that still counts as touching
var push_grace_time := 0.12 #keeps the push going through the player's contact stutter

var shot_push_scale := 2.0 #velocity added = bullet knockback_strength * this

var wind_force_scale := 60.0 #PhysWindColumn speed -> px/s^2, matches the player (speed 4 ~= gravity)
var max_wind_speed := 120.0

var crush_min_fall_speed := 40.0
var thud_min_fall_speed := 80.0

#ground support: probes cast down from inside the cart instead of trusting the box contact,
#so it hovers a hair above the floor and never catches on tile seams or slips into one-way ssp
const CART_SIZE := Vector2(16, 16)
var ground_probe_inset := 1.0 #px in from each side
var ground_probe_up := 6.0 #how far the cart can sink before it stops being caught
var ground_probe_down := 1.0 #how far below the cart still counts as ground
var ground_hover := 0.25 #px gap kept between cart and floor

var roll_min_speed := 2.0

var carry_accel := 400.0 #how hard props on top get dragged along to match the cart (friction)

var block_dir := Vector2.ZERO #armor on all sides, read by Bullet.armor_check()
var crush_targets := []
var push_dir := 0
var push_grace := 0.0
var pending_shot_velocity := 0.0
var is_grounded := true
var last_fall_speed := 0.0

var ground_left := false
var ground_right := false
var floor_velocity_x := 0.0 #conveyor belt / cart underneath
var rolling_speed := 0.0 #speed relative to the floor, drives the wheel animation

@onready var ap: AnimationPlayer = $AnimationPlayer


func setup():
	is_wind_affected = true
	$Sprite2D.position.y += ground_hover #physics hovers above the floor, the sprite shouldn't
	blocked.connect(_on_blocked)
	w.emit_signal("finished_spawn_entities_step")


func _physics_process(delta):
	_update_push(delta)
	_update_crush()
	_update_carry(delta)
	_update_animation()


func _integrate_forces(state: PhysicsDirectBodyState2D):
	var step := state.step
	var vel := state.linear_velocity
	var was_grounded := is_grounded

	var left_hit := _probe_ground(state, ground_probe_inset)
	var right_hit := _probe_ground(state, CART_SIZE.x - ground_probe_inset)
	ground_left = !left_hit.is_empty()
	ground_right = !right_hit.is_empty()
	is_grounded = ground_left || ground_right
	floor_velocity_x = _get_floor_velocity_x(left_hit, right_hit)

	#landing
	if is_grounded && !was_grounded && last_fall_speed >= thud_min_fall_speed:
		am.play("block_thud", self)
	last_fall_speed = max(vel.y, 0.0)

	#shots
	vel.x += pending_shot_velocity
	pending_shot_velocity = 0.0

	#wind
	var wind_accel := Vector2.ZERO #px/s^2
	for area in _get_strongest_winds():
		if is_grounded && area.wind_dir.y > 0.0: continue
		wind_accel += area.wind_dir * area.speed * wind_force_scale
	var wind_x := wind_accel.x * step
	if wind_x != 0.0:
		if abs(vel.x) < max_wind_speed || sign(vel.x) != sign(wind_x):
			vel.x = clampf(vel.x + wind_x, -max_wind_speed, max_wind_speed)

	#vertical: rest on the floor unless updraft beats gravity
	var lifting := wind_accel.y + state.total_gravity.y < 0.0
	if is_grounded && vel.y >= 0.0 && !lifting:
		vel.y = 0.0
		var floor_y := INF
		if ground_left: floor_y = left_hit.position.y
		if ground_right: floor_y = min(floor_y, right_hit.position.y)
		var xform := state.transform
		xform.origin.y = floor_y - CART_SIZE.y - ground_hover
		state.transform = xform
	else:
		vel.y += wind_accel.y * step

	#push / friction, relative to the floor so conveyors carry it (in the air it keeps its momentum)
	if is_grounded:
		var rel := vel.x - floor_velocity_x
		var pushing_faster: bool = push_dir != 0 && (sign(rel) != push_dir || abs(rel) < push_max_speed)
		if pushing_faster:
			var t := clampf(abs(rel) / push_max_speed, 0.0, 1.0)
			var accel := lerpf(push_start_accel, push_full_accel, t)
			rel = move_toward(rel, push_dir * push_max_speed, accel * step)
		else: #wind still has to overcome friction, so weak wind can't budge it
			rel = move_toward(rel, 0.0, ground_friction * step)
		vel.x = rel + floor_velocity_x
		rolling_speed = rel

		if !can_fall_off_ledges:
			if vel.x > 0.0 && !ground_right:
				vel.x = 0.0
			elif vel.x < 0.0 && !ground_left:
				vel.x = 0.0
	else:
		rolling_speed = vel.x

	state.linear_velocity = vel


#ray hit dictionary for the floor under the given x offset, empty if there's no floor in range
func _probe_ground(state: PhysicsDirectBodyState2D, x_offset: float) -> Dictionary:
	var origin := state.transform.origin
	var bottom := origin.y + CART_SIZE.y
	var from := Vector2(origin.x + x_offset, bottom - ground_probe_up)
	var to := Vector2(origin.x + x_offset, bottom + ground_probe_down + ground_hover)
	var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask, [get_rid()])
	return state.get_space_state().intersect_ray(query)


#conveyor belts use StaticBody2D.constant_linear_velocity, carts/props underneath use their own velocity
func _get_floor_velocity_x(left_hit: Dictionary, right_hit: Dictionary) -> float:
	var total := 0.0
	var count := 0
	for hit in [left_hit, right_hit]:
		if hit.is_empty(): continue
		var collider = hit.collider
		if collider is StaticBody2D:
			total += collider.constant_linear_velocity.x
		elif collider is RigidBody2D:
			total += collider.linear_velocity.x
		count += 1
	return total / count if count > 0 else 0.0


### CARRYING ###

#props resting on top get dragged toward the cart's speed. Anything that holds them back harder
#(a wall, a ceiling block) just stops them and the cart rolls out from under.
func _update_carry(delta):
	for body in $CarryDetector.get_overlapping_bodies():
		if body == self || !(body is RigidBody2D) || body.is_in_group("Minecarts"): continue
		if !body.is_in_group("PhysicsProps") || body.freeze: continue
		if body.linear_velocity.y < -1.0: continue #being launched up, not resting
		body.linear_velocity.x = move_toward(body.linear_velocity.x, linear_velocity.x, carry_accel * delta)


### ANIMATION ###

func _update_animation():
	var speed: float = abs(rolling_speed)
	if speed > roll_min_speed:
		ap.speed_scale = speed / push_max_speed
		if !ap.is_playing():
			ap.play("Roll")
	elif ap.is_playing():
		ap.pause()


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
