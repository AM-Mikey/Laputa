extends PhysicsProp

## Pushable, indestructible minecart.
## - Player pushes it by walking into its side while on flat floor (not while riding on top, not on slopes).
## - Builds up speed slowly, then rolls on with inertia and slows down from ground friction.
## - Rolls on flat floor and 1:2, 1:1 and 2:1 slopes, sliding down them under gravity.
## - Keeps its momentum when it rolls off a ledge or the top of a ramp (if allowed).
## - Crushes players/enemies it falls onto.
## - Armor layer: bullets never pass through it, and nudge it based on their knockback_strength.
## - Pushed by PhysFan wind. Water gravity comes from the Water Area2D's gravity override.
## - Rides conveyor belts (and other carts): friction works relative to whatever it's standing on.
## - Carries physics props (breakblocks) on top with friction, unless something pushes them off.
##   The top it offers riders is always flat, so riders never have to rotate on a slope.

#a var (not const like other props) so variants that extend this script can set their own in _init()
var ICON: Texture2D = preload("res://assets/Prop/MinecartIcon.png")

signal blocked(bullet, body) #emitted by Bullet.armor_check()

@export var fast := false
## Rideable carts are empty: the CargoSprite (load drawn inside the cart) is hidden.
@export var rideable := false: set = set_rideable
@export var can_fall_off_ledges := true
var crush_players := true
var crush_enemies := true
var squish_enemies := true #enemies the cart drives into a wall/ceiling
var squish_players := true #same for the player

var push_max_speed := 60.0 #keep below player walk speed (90) so the player stays in contact
var push_start_accel := 30.0 #accel when starting from rest, feels heavy
var push_full_accel := 120.0 #accel once rolling
var ground_friction := 90.0 #decel when nothing is pushing, controls how far it coasts
var slope_friction := 30.0 #lower on slopes so gravity always wins and it never sits stuck (and unpushable) on one
var push_reach := 2.0 #px gap between player and cart that still counts as touching
var push_grace_time := 0.12 #keeps the push going through the player's contact stutter
var max_roll_speed := 240.0 #cap for long slopes

#fast carts (spiked or not) swap these in over the values above in setup()
const FAST_TEXTURE := preload("res://assets/Prop/MinecartFast.png")
const FAST_CARGO_TEXTURE := preload("res://assets/Prop/MinecartFastCargo.png")
var fast_push_max_speed := 90.0 #same as player walk speed, so the player can push it at full walking pace
var fast_push_start_accel := 120.0
var fast_push_full_accel := 360.0
var fast_max_roll_speed := 360.0

var shot_push_scale := 2.0 #velocity added = bullet knockback_strength * this

var wind_force_scale := 60.0 #PhysWindColumn speed -> px/s^2, matches the player (speed 4 ~= gravity)
var max_wind_speed := 120.0

var crush_min_fall_speed := 40.0
var thud_min_fall_speed := 80.0

#ground support: rays cast down under both wheels (plus the middle) instead of trusting the box contact.
#The cart hovers a hair above the ground, so it never catches on tile seams or slips into one-way ssp,
#and the line between the wheels gives the slope it's on.
const CART_SIZE := Vector2(16, 16)
var wheel_offset := 4.5 #px from the middle to each wheel probe
var ground_probe_up := 4.0 #how far above the expected ground the probes start
var ground_probe_down := 2.0 #how far below the expected ground still counts as ground (plus speed)
var ground_hover := 0.25 #px gap kept between cart and floor
var shape_clearance := 2.0 #gap between the collision shape and the ground while on a slope
var flat_clearance := 0.75 #small on flat ground so the shape still reaches down into switchplates
var chamfer_margin := 3.0 #how far the shape's lower corners are cut back for slope bottoms

enum Grade {FLAT, SLIGHT, SLOPE, STEEP}
const GRADE_RISE := [0.0, 0.5, 1.0, 2.0] #px down per px across (1:2, 1:1, 2:1)
const GRADE_ANIM := ["Flat", "SlightSlope", "Slope", "SteepSlope"]
const GRADE_LIMITS := [0.236, 0.721, 1.387] #rise halfway (by angle) between neighbouring grades
const MAX_SLOPE_RISE := 2.75 #anything steeper between the wheels is a step, not a slope
#local y of the art's ground line under the cart's middle, per grade. Measured from the sprite sheet
#in setup(), these are the fallbacks if the texture can't be read.
const GRADE_SUPPORT_DEFAULT := [16.0, 18.5, 19.0, 29.0]

var roll_min_speed := 2.0

var roll_sfx_full_speed := 160.0 #rolling speed (px/s) where the rolling loop reaches full volume
var roll_sfx_max_volume := 1.0 #0-1, same scale as am.play()
var roll_sfx_player: Node

var carry_accel := 400.0 #how hard props on top get dragged along to match the cart (friction)

var squish_depth := 3.0 #how far the cart has to be pushed into an enemy that can't get out of the way

#riding (player state src/Player/Minecart.gd). A ridden cart stays a normal solid cart (pushes, squishes,
#crushes, presses switchplates); it only drops its armor layer, so it doesn't deflect shots. The rider and the
#rider's own shots ignore it (collision exceptions / Bullet.is_riders_cart()). Enemies and props that end up
#on top are shoved off the side (_update_top_shove), since the rider's head is in that space.
const ARMOR_LAYER := 32
var top_shove_speed := 120.0 #px/s sideways that props on top of a ridden cart are pushed off at
var _top_shove_dirs := {} #prop on top -> side it's being shoved to (-1/1), kept so it doesn't flip midway
#enemies in the "CartBumpable" group that land on a ridden cart are bumped off with a short hop (see
#_start_hop). Others (flying, path-following, scripted) are left alone.
var hop_time := 0.25 #s the hop off the side takes
var hop_height := 6.0 #px the hop rises at its peak
var hop_margin := 1.0 #px past the cart's edge the enemy's near side ends up
var _hops := {} #enemy -> {dir, dist, t, offset, paused (we set its `disabled`)}
var rider: Node = null
var _former_rider: Node = null #just got out, still overlapping the cart: keep ignoring it until clear
var _base_layer := 0

var block_dir := Vector2.ZERO #armor on all sides, read by Bullet.armor_check()
var crush_targets := []
var push_dir := 0
var push_grace := 0.0
var pending_shot_velocity := 0.0
var is_grounded := true
var last_fall_speed := 0.0

var grade := Grade.FLAT
var grade_dir := 1 #1 = ground goes down to the right (how the art is drawn), -1 = up to the right (flipped)
var floor_velocity_x := 0.0 #conveyor belt / cart underneath
var rolling_speed := 0.0 #speed along the ground relative to it, drives the wheel animation
var ground_tangent := Vector2.RIGHT #direction along the ground last step

var grade_support := GRADE_SUPPORT_DEFAULT.duplicate()
var grade_shapes := {} #Vector2i(grade, dir) -> ConvexPolygonShape2D
var squish_shapes := {} #same shapes shrunk by squish_depth
var applied_look := Vector2i(-1, 0)
var sprite_base_pos := Vector2.ZERO
var carry_base_pos := Vector2.ZERO

@onready var ap: AnimationPlayer = $AnimationPlayer


func setup():
	is_wind_affected = true
	_base_layer = collision_layer
	$CarryDetector.set_collision_mask_value(2, true) #enemies on top: block getting in / shoved off when ridden
	if fast:
		_apply_fast()
	set_rideable(rideable)
	_measure_grade_support()
	sprite_base_pos = $Sprite2D.position + Vector2(0, ground_hover) #physics hovers above the floor, the sprite shouldn't
	carry_base_pos = $CarryDetector/CollisionShape2D.position + Vector2(0, ground_hover)
	_build_grade_shapes()
	_apply_look()
	blocked.connect(_on_blocked)
	w.emit_signal("finished_spawn_entities_step")


#the cargo sheet is laid out like the cart's (same frame size, not centered), so it copies the cart
#sprite's position (raised on slopes) and flip, which mirrors both around the cart's middle
func _sync_cargo_sprite():
	var cargo := get_node_or_null("CargoSprite") as Sprite2D
	if cargo:
		cargo.position = $Sprite2D.position
		cargo.flip_h = $Sprite2D.flip_h


func set_rideable(val: bool):
	rideable = val
	var cargo := get_node_or_null("CargoSprite") as Sprite2D #not every variant has one (spiked cart)
	if cargo:
		cargo.visible = !rideable


#runs before anything reads the sprite sheet (grade support is measured from it)
func _apply_fast():
	$Sprite2D.texture = FAST_TEXTURE
	var cargo := get_node_or_null("CargoSprite") as Sprite2D
	if cargo:
		cargo.texture = FAST_CARGO_TEXTURE
	push_max_speed = fast_push_max_speed
	push_start_accel = fast_push_start_accel
	push_full_accel = fast_push_full_accel
	max_roll_speed = fast_max_roll_speed


func _physics_process(delta):
	_update_former_rider()
	_update_push(delta)
	_update_crush()
	_update_carry(delta)
	_update_ride_push()
	_update_top_shove(delta)
	_update_hops(delta)
	_update_squish()
	_apply_look()
	_update_animation()
	_update_roll_sfx()


func _integrate_forces(state: PhysicsDirectBodyState2D):
	var step := state.step
	var vel := state.linear_velocity
	var was_grounded := is_grounded

	#wind
	var wind_accel := Vector2.ZERO #px/s^2
	for area in _get_strongest_winds():
		if was_grounded && area.wind_dir.y > 0.0: continue
		wind_accel += area.wind_dir * area.speed * wind_force_scale
	var lifting := wind_accel.y + state.total_gravity.y * gravity_scale < 0.0 #updraft beats gravity

	var ground := {} if lifting else _find_ground(state, vel, was_grounded)
	is_grounded = !ground.is_empty()

	#landing
	if is_grounded && !was_grounded && last_fall_speed >= thud_min_fall_speed:
		am.play("block_thud", self)

	if is_grounded:
		vel = _roll(state, vel, ground, wind_accel, was_grounded)
	else: #in the air it keeps its momentum, the engine applies gravity
		grade = Grade.FLAT
		floor_velocity_x = 0.0
		last_fall_speed = max(vel.y, 0.0)
		vel.x += pending_shot_velocity
		vel.x = _add_wind(vel.x, wind_accel.x * step)
		vel.y += wind_accel.y * step
		rolling_speed = vel.x
	pending_shot_velocity = 0.0

	state.linear_velocity = vel


#moving along the ground. Speed is kept as one number along the ground line, so it carries over
#between flat floor and slopes. Gravity along the slope comes from the engine: it adds gravity to the
#velocity every step and the part of that along the ground stays in the speed.
func _roll(state: PhysicsDirectBodyState2D, vel: Vector2, ground: Dictionary, wind_accel: Vector2, was_grounded: bool) -> Vector2:
	var step := state.step
	var k: float = ground.k
	grade = _grade_for(k)
	if k != 0.0:
		grade_dir = 1 if k > 0.0 else -1
	last_fall_speed = 0.0

	#bottom middle of the cart's box sits on the ground line (the sprite and shape are offset per grade)
	var xform := state.transform
	xform.origin.y = ground.y - CART_SIZE.y - ground_hover
	state.transform = xform

	#speed is measured along the ground it was on, then carried onto the new ground's direction, so it
	#doesn't bleed off at the bottom/top of a slope. Landing only keeps the part along the ground.
	var t := Vector2(1.0, k).normalized()
	floor_velocity_x = ground.floor_vx if grade == Grade.FLAT else 0.0
	var floor_vel := Vector2(floor_velocity_x, 0.0)
	var rel := (vel - floor_vel).dot(ground_tangent if was_grounded else t)
	ground_tangent = t

	rel += pending_shot_velocity * t.x
	rel = _add_wind(rel, wind_accel.dot(t) * step)

	#push / friction (wind and slopes still have to overcome friction, so weak wind can't budge it)
	var pushing_faster: bool = push_dir != 0 && grade == Grade.FLAT \
		&& (sign(rel) != push_dir || abs(rel) < push_max_speed)
	if pushing_faster:
		var speed_t := clampf(abs(rel) / push_max_speed, 0.0, 1.0)
		var accel := lerpf(push_start_accel, push_full_accel, speed_t)
		rel = move_toward(rel, push_dir * push_max_speed, accel * step)
	else:
		var friction := ground_friction if grade == Grade.FLAT else slope_friction
		rel = move_toward(rel, 0.0, friction * step)
	rel = clampf(rel, -max_roll_speed, max_roll_speed)
	rolling_speed = rel
	vel = t * rel + floor_vel

	if !can_fall_off_ledges && grade == Grade.FLAT:
		if vel.x > 0.0 && !_has_ledge_ground(state, CART_SIZE.x - 1.0):
			vel.x = 0.0
		elif vel.x < 0.0 && !_has_ledge_ground(state, 1.0):
			vel.x = 0.0
	return vel


#returns {y = ground height under the middle, k = rise per px (+ = down to the right), floor_vx}
#or {} when there's no ground in reach
func _find_ground(state: PhysicsDirectBodyState2D, vel: Vector2, was_grounded: bool) -> Dictionary:
	var origin := state.transform.origin
	var cx := origin.x + CART_SIZE.x / 2.0
	var floor_y := origin.y + CART_SIZE.y + ground_hover #ground under the middle if nothing changed
	var ms: float = grade_dir * GRADE_RISE[grade]

	var up: float
	var down: float
	if was_grounded: #follow the ground, reaching further the faster it goes
		var rise: float = GRADE_RISE[grade] * wheel_offset
		var travel: float = abs(vel.x) * state.step * MAX_SLOPE_RISE
		up = rise + ground_probe_up + travel
		down = rise + ground_probe_down + travel
	else: #only land when it gets there
		if vel.y < -1.0: return {}
		ms = 0.0
		up = ground_probe_up + 2.0
		down = 1.0 + max(vel.y, 0.0) * state.step
	var from_y := floor_y - up
	var to_y := floor_y + down

	var back := _ray(state, cx - wheel_offset, from_y, to_y)
	var front := _ray(state, cx + wheel_offset, from_y, to_y)

	#a wheel on top of a step (flat ground at another height) isn't a slope: ignore the wheel that's
	#further from where the cart is, the box stops at the step / the cart rolls off the edge
	if !back.is_empty() && !front.is_empty():
		var gap: float = front.position.y - back.position.y
		var is_step: bool = abs(gap) > 2.0 * wheel_offset * MAX_SLOPE_RISE \
			|| (abs(gap) > 1.0 && !_is_slope(back.normal) && !_is_slope(front.normal))
		if is_step:
			var back_off: float = abs(back.position.y - (floor_y - ms * wheel_offset))
			var front_off: float = abs(front.position.y - (floor_y + ms * wheel_offset))
			if back_off <= front_off: front = {}
			else: back = {}

	#straddling a peak the ground drops away under both wheels, past their normal reach. As long as the
	#middle is on the ground, look further down for the slopes on each side
	var middle := _ray(state, cx, from_y, to_y)
	if back.is_empty() && front.is_empty() && !middle.is_empty():
		var deep: float = to_y + wheel_offset * MAX_SLOPE_RISE
		back = _ray(state, cx - wheel_offset, from_y, deep)
		front = _ray(state, cx + wheel_offset, from_y, deep)
		if back.is_empty() && front.is_empty():
			back = middle #a spike too thin for the wheels: rest on the middle

	var k := 0.0
	var ground_y := 0.0
	if !back.is_empty() && !front.is_empty():
		k = (front.position.y - back.position.y) / (front.position.x - back.position.x)
		ground_y = (front.position.y + back.position.y) / 2.0
		#over a peak (rising under the back wheel, falling under the front) the line between the wheels
		#is about level, so it would count as flat and friction could stop it on top. Take the slope on
		#the side it's heading for (or that its middle is on) instead, so it always rolls off
		if _is_slope(back.normal) && _is_slope(front.normal) 				&& _normal_k(back.normal) < 0.0 && _normal_k(front.normal) > 0.0:
			var side := signf(vel.x)
			if absf(vel.x) < 1.0:
				side = 1.0
				if !middle.is_empty() && _is_slope(middle.normal):
					side = signf(_normal_k(middle.normal))
				elif rolling_speed != 0.0:
					side = signf(rolling_speed)
			k = _normal_k(front.normal) if side > 0.0 else _normal_k(back.normal)
	elif !back.is_empty() || !front.is_empty():
		var hit: Dictionary = back if !back.is_empty() else front
		if _is_slope(hit.normal):
			k = _normal_k(hit.normal)
		ground_y = hit.position.y + k * (cx - hit.position.x)
	else:
		return {}

	#going over a peak the line between the wheels dips below it, rest on the peak instead
	if !middle.is_empty():
		ground_y = min(ground_y, middle.position.y)

	if abs(k) < 0.02: k = 0.0
	return {"y": ground_y, "k": k, "floor_vx": _get_floor_velocity_x(back, front)}


func _ray(state: PhysicsDirectBodyState2D, x: float, from_y: float, to_y: float) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, to_y), collision_mask, [get_rid()])
	return state.get_space_state().intersect_ray(query)


#rise per px of the ground with this normal (+ = down to the right)
func _normal_k(normal: Vector2) -> float:
	return -normal.x / normal.y


func _is_slope(normal: Vector2) -> bool:
	return normal.y < -0.3 && normal.y > -0.98


func _grade_for(k: float) -> int:
	var a: float = abs(k)
	if a < GRADE_LIMITS[0]: return Grade.FLAT
	if a < GRADE_LIMITS[1]: return Grade.SLIGHT
	if a < GRADE_LIMITS[2]: return Grade.SLOPE
	return Grade.STEEP


#ground under one edge for the can_fall_off_ledges check. A slope going down counts as ground.
func _has_ledge_ground(state: PhysicsDirectBodyState2D, x_offset: float) -> bool:
	var origin := state.transform.origin
	var floor_y := origin.y + CART_SIZE.y + ground_hover
	var hit := _ray(state, origin.x + x_offset, floor_y - ground_probe_up, floor_y + CART_SIZE.x * GRADE_RISE[Grade.STEEP])
	if hit.is_empty(): return false
	return hit.position.y <= floor_y + 1.0 || _is_slope(hit.normal)


#conveyor belts use StaticBody2D.constant_linear_velocity, carts/props underneath use their own velocity
func _get_floor_velocity_x(back: Dictionary, front: Dictionary) -> float:
	var total := 0.0
	var count := 0
	for hit in [back, front]:
		if hit.is_empty(): continue
		var collider = hit.collider
		if collider is StaticBody2D:
			total += collider.constant_linear_velocity.x
		elif collider is RigidBody2D:
			total += collider.linear_velocity.x
		count += 1
	return total / count if count > 0 else 0.0


func _add_wind(speed: float, dv: float) -> float:
	if dv == 0.0: return speed
	if sign(speed) != sign(dv): return speed + dv
	if abs(speed) >= max_wind_speed: return speed #wind can't speed it up past this, but doesn't slow it
	return sign(dv) * min(abs(speed + dv), max_wind_speed)


### LOOK (sprite + collision shape per grade) ###

#the slope frames are the cart rotated around its middle, so their wheels meet the ground at a different
#height than the flat frame's. Read where from the art so redrawn frames line up on their own.
func _measure_grade_support():
	grade_support = GRADE_SUPPORT_DEFAULT.duplicate()
	var sprite: Sprite2D = $Sprite2D
	if !sprite.texture: return
	var img: Image = sprite.texture.get_image()
	if !img || img.is_empty(): return
	if img.is_compressed(): img.decompress()
	var fw := img.get_width() / sprite.hframes
	var fh := img.get_height() / sprite.vframes
	var mid_x := CART_SIZE.x / 2.0 - sprite.position.x #frame x under the cart's middle
	for g in Grade.values():
		var anim: String = GRADE_ANIM[g]
		if !ap.has_animation(anim): continue
		var a := ap.get_animation(anim)
		var track := a.find_track(NodePath("Sprite2D:frame"), Animation.TYPE_VALUE)
		if track == -1 || a.track_get_key_count(track) == 0: continue
		var row: int = int(a.track_get_key_value(track, 0)) / sprite.hframes
		var rise: float = GRADE_RISE[g]
		var best := -INF
		for col in sprite.hframes:
			for y in fh:
				for x in fw:
					if img.get_pixel(col * fw + x, row * fh + y).a > 0.5:
						best = max(best, (y + 1) - rise * x) #lowest pixel corner along the slope
		if best > -INF:
			grade_support[g] = rise * mid_x + best + sprite.position.y


func _build_grade_shapes():
	grade_shapes.clear()
	for g in Grade.values():
		for dir in [1, -1]:
			var shape := _build_shape(g, dir)
			grade_shapes[Vector2i(g, dir)] = shape
			var squish := ConvexPolygonShape2D.new()
			var shrunk := Geometry2D.offset_polygon(shape.points, -squish_depth)
			squish.points = shrunk[0] if !shrunk.is_empty() else PackedVector2Array()
			squish_shapes[Vector2i(g, dir)] = squish


#a box the size of the cart, raised to where the art sits for this grade (so the top riders stand on is
#flat and lines up with the art), cut so it never touches the ground: above the ground line, and with
#the lower corners bevelled for the bottom of a slope where the ground starts rising beside a wheel.
func _build_shape(g: int, dir: int) -> ConvexPolygonShape2D:
	var ms: float = dir * GRADE_RISE[g]
	var steepest: float = GRADE_RISE[Grade.STEEP]
	#shifted down by the hover like the sprite, so on flat ground the top is level with the tiles beside it
	#(otherwise it's a 0.25px step the player can't walk up onto)
	var top: float = CART_SIZE.y - grade_support[g] + ground_hover
	var clear := flat_clearance if g == Grade.FLAT else shape_clearance
	var mid := CART_SIZE.x / 2.0
	var ground_at := func(x: float) -> float: return CART_SIZE.y + ms * (x - mid) - clear

	var poly := PackedVector2Array([
		Vector2(0, top), Vector2(CART_SIZE.x, top),
		Vector2(CART_SIZE.x, top + CART_SIZE.y), Vector2(0, top + CART_SIZE.y)])
	poly = _clip_below_line(poly, ms, ground_at.call(0.0))
	var xf := mid + wheel_offset
	var xb := mid - wheel_offset
	poly = _clip_below_line(poly, -steepest, ground_at.call(xf) - chamfer_margin + steepest * xf)
	poly = _clip_below_line(poly, steepest, ground_at.call(xb) - chamfer_margin - steepest * xb)

	var points := PackedVector2Array()
	for p in poly:
		if points.is_empty() || p.distance_to(points[-1]) > 0.01:
			points.append(p - CART_SIZE / 2.0) #CollisionShape2D sits at the box middle
	if points.size() > 1 && points[0].distance_to(points[-1]) <= 0.01:
		points.remove_at(points.size() - 1)
	var shape := ConvexPolygonShape2D.new()
	shape.points = points
	return shape


#keeps the part of a convex polygon where y <= a * x + b
func _clip_below_line(poly: PackedVector2Array, a: float, b: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var dp := p.y - (a * p.x + b)
		var dq := q.y - (a * q.x + b)
		if dp <= 0.0: out.append(p)
		if (dp <= 0.0) != (dq <= 0.0):
			out.append(p.lerp(q, dp / (dp - dq)))
	return out


func _apply_look():
	var dir := grade_dir if grade != Grade.FLAT else 1
	var look := Vector2i(grade, dir)
	if look == applied_look: return
	applied_look = look
	var shape: Shape2D = grade_shapes[look]
	$CollisionShape2D.shape = shape
	$PhysicsLayerBody/CollisionShape2D.shape = shape
	$SquishDetector/CollisionShape2D.shape = squish_shapes[look]
	var offset := Vector2(0, CART_SIZE.y - grade_support[grade]) #slope frames sit higher than the flat one
	$Sprite2D.position = sprite_base_pos + offset
	$Sprite2D.flip_h = dir < 0
	_sync_cargo_sprite()
	$CarryDetector/CollisionShape2D.position = carry_base_pos + offset


### CARRYING ###

#props resting on top get dragged toward the cart's speed. Anything that holds them back harder
#(a wall, a ceiling block) just stops them and the cart rolls out from under.
func _update_carry(delta):
	if rider: return #a ridden cart shoves things off its top instead (_update_top_shove)
	for body in $CarryDetector.get_overlapping_bodies():
		if body == self || !(body is RigidBody2D) || body.is_in_group("Minecarts"): continue
		if !body.is_in_group("PhysicsProps") || body.is_in_group("NoPropCollision") || body.freeze: continue
		if body.linear_velocity.y < linear_velocity.y - 30.0: continue #being launched up, not resting
		body.linear_velocity.x = move_toward(body.linear_velocity.x, linear_velocity.x, carry_accel * delta)
		if linear_velocity.y > body.linear_velocity.y: #cart heading downhill, keep the load seated
			body.linear_velocity.y = linear_velocity.y


func is_carrying(body) -> bool: #used by PhysicsProp.rests_on_minecart()
	return $CarryDetector.overlaps_body(body)


### SQUISHING ###

#players/enemies the cart has driven into a wall or ceiling, see PhysicsProp.squish_pinned()
func _update_squish():
	squish_pinned($SquishDetector, $CrushDetector, squish_enemies, squish_players)


### SFX ###

#rolling loop, follows the cart, only while it's on the ground and rolling. Louder the faster it rolls
#(speed along the ground, so it's quiet while just riding a conveyor, same as the wheels).
func _update_roll_sfx():
	var speed: float = abs(rolling_speed)
	var rolling := is_grounded && speed > roll_min_speed
	if !rolling:
		_stop_roll_sfx()
		return
	var volume := roll_sfx_max_volume * clampf(speed / roll_sfx_full_speed, 0.0, 1.0)
	if !is_instance_valid(roll_sfx_player): #not started yet, or freed by am.stop_sfx() / the player limit
		roll_sfx_player = am.play("minecart", self, null, volume, 0.0)
	else:
		am.set_player_volume(roll_sfx_player, volume)

func _stop_roll_sfx():
	if is_instance_valid(roll_sfx_player):
		am.clear_player_by_node(roll_sfx_player)
	roll_sfx_player = null

func _exit_tree():
	_stop_roll_sfx()
	for enemy in _hops.keys(): #don't leave an enemy paused if the cart goes away mid-hop
		_end_hop(enemy)


### ANIMATION ###

func _get_grade_anim() -> String: #variants can pick other animations (MinecartSpikes uses reverse slopes)
	return GRADE_ANIM[grade]


func _update_animation():
	var anim: String = _get_grade_anim()
	if !ap.has_animation(anim): return
	if ap.assigned_animation != anim: #switch grade, keep the wheels' phase
		var was_playing := ap.is_playing()
		var pos := ap.current_animation_position if ap.assigned_animation != "" else 0.0
		ap.play(anim)
		ap.seek(fmod(pos, ap.current_animation_length), true)
		if !was_playing:
			ap.pause()

	var speed: float = abs(rolling_speed)
	if speed > roll_min_speed:
		ap.speed_scale = speed / push_max_speed
		if !ap.is_playing():
			ap.play(anim)
	elif ap.is_playing():
		ap.pause()


### PUSHING ###

func _update_push(delta):
	var dir := _get_player_push_dir() if is_grounded && grade == Grade.FLAT else 0
	if dir != 0:
		push_dir = dir
		push_grace = push_grace_time
	elif grade != Grade.FLAT: #no pushing on slopes, drop it straight away
		push_dir = 0
		push_grace = 0.0
	else:
		push_grace -= delta
		if push_grace <= 0.0:
			push_dir = 0


func _get_player_push_dir() -> int:
	if rider: #riding: left/right drives the cart
		return int(sign(rider.move_dir.x))
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


func _get_rect() -> Rect2: #the cart's box on flat ground
	return Rect2(global_position, CART_SIZE)


### RIDING ###

func can_be_ridden() -> bool:
	return rideable && rider == null && !is_ride_blocked()


#a box (or any prop) or an enemy on top of the cart, even partly: getting in under it would put it on the
#rider's head (and the cart's crush/squish checks would kill them)
func is_ride_blocked() -> bool:
	for body in $CarryDetector.get_overlapping_bodies():
		if body == self: continue
		if body is RigidBody2D && !body.is_in_group("NoPropCollision"):
			return true
		if body.is_in_group("Enemies") && !body.get("dead"):
			return true
	return false


func set_rider(new_rider: Node):
	if new_rider:
		rider = new_rider
		_former_rider = null
		rider.add_collision_exception_with(self)
		collision_layer = _base_layer & ~ARMOR_LAYER
	else:
		_former_rider = rider
		rider = null
		collision_layer = _base_layer
		_top_shove_dirs.clear() #hops already under way finish on their own


#a ridden cart shoves props in front of it along at its own speed. Their static friction (breakaway_speed)
#would otherwise stop a cart driven at walking pace, which is what keeps a cart pushed on foot from moving
#boxes. Anything they're pressed against (a wall, a heavier stack) still stops both. Enemies are pushed by
#the normal collision, like with any cart.
func _update_ride_push():
	if !rider || !is_grounded || abs(linear_velocity.x) < 1.0: return
	var dir := signf(linear_velocity.x)
	var rect := _get_rect()
	var strip := RectangleShape2D.new()
	strip.size = Vector2(2.0, CART_SIZE.y - 6.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = strip
	var edge_x: float = rect.end.x if dir > 0.0 else rect.position.x
	query.transform = Transform2D(0.0, Vector2(edge_x + dir, rect.get_center().y))
	query.collision_mask = 8 #props are on the world layer
	query.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 8):
		var body = hit.collider
		if !(body is PhysicsProp) || body.is_in_group("Minecarts") || body.is_in_group("NoPropCollision") || body.freeze:
			continue
		body._at_rest = false #skip its static friction this step
		if body.linear_velocity.x * dir < abs(linear_velocity.x):
			body.linear_velocity.x = linear_velocity.x


#nothing stays on top of a ridden cart (the rider's head is there): props on top (CarryDetector) are pushed
#off the nearer side, away from the rider (dead centre: off the back), trying the other side if that one is
#blocked. CartBumpable enemies are bumped off with a hop instead (_start_hop).
func _update_top_shove(delta: float):
	if !rider: return
	var still_on := {}
	for body in $CarryDetector.get_overlapping_bodies():
		if body == self: continue
		if body is CharacterBody2D && body.is_in_group("CartBumpable"):
			if !body.get("dead") && !_hops.has(body) && _is_standing_on_me(body):
				_start_hop(body)
			continue
		if !(body is PhysicsProp) || body.is_in_group("Minecarts") || body.is_in_group("NoPropCollision") || body.freeze:
			continue
		var dir: int = _top_shove_dirs.get(body, 0)
		if dir == 0: dir = _off_side(body)
		var step := Vector2(dir * top_shove_speed * delta, 0.0)
		if body.test_move(body.global_transform, step): #that way is blocked
			if body.test_move(body.global_transform, -step): continue
			dir = -dir
		still_on[body] = dir
		body._at_rest = false #skip its static friction
		body.linear_velocity.x = linear_velocity.x + dir * top_shove_speed
	_top_shove_dirs = still_on


#landed on this cart, not just passing through the strip above it mid-jump (a frog jumping up beside the
#cart crosses it): bumping it then would carry it sideways in mid-air and its jump would bring it right back
func _is_standing_on_me(enemy: CharacterBody2D) -> bool:
	if !enemy.is_on_floor(): return false
	for i in enemy.get_slide_collision_count():
		var col := enemy.get_slide_collision(i)
		if col.get_collider() == self && col.get_normal().y < -0.7:
			return true
	return false


#the side to push something off: away from the rider (the cart's middle), dead centre goes off the back
func _off_side(body) -> int:
	var dx: float = _get_body_center(body).x - (global_position.x + CART_SIZE.x / 2.0)
	if abs(dx) >= 1.0: return int(signf(dx))
	if abs(linear_velocity.x) > 1.0: return -int(signf(linear_velocity.x))
	return 1


#bump an enemy off the top: the cart takes over its movement for hop_time (its AI is paused through the
#`disabled` flag every enemy has, so it doesn't walk back in and jitter), moving it along a small arc just
#far enough sideways that its near side clears the cart's edge, whatever its size. Then its AI and gravity
#take over again. If neither side has room it's squished, like being pinned by the cart.
#The enemy ignores this cart for the hop: one landing on a cart that's driving into it is already slightly
#inside it, so the cart itself would otherwise count as blocking both sides (and squish it).
func _start_hop(enemy: CharacterBody2D):
	enemy.add_collision_exception_with(self)
	var dir := _off_side(enemy)
	var dist := _hop_distance(enemy, dir)
	var probe := Vector2(dir * min(dist, 4.0), -1.0)
	if enemy.test_move(enemy.global_transform, probe):
		dir = -dir
		dist = _hop_distance(enemy, dir)
		if enemy.test_move(enemy.global_transform, Vector2(dir * min(dist, 4.0), -1.0)):
			enemy.remove_collision_exception_with(self)
			if squish_enemies: enemy.hit(999, Vector2.ZERO, $CrushDetector)
			return
	var paused: bool = !enemy.disabled
	enemy.disabled = true
	enemy.velocity = Vector2.ZERO
	_hops[enemy] = {"dir": dir, "dist": dist, "t": 0.0, "offset": Vector2.ZERO, "paused": paused}


#how far the enemy has to move sideways for its near edge to clear the cart's edge
func _hop_distance(enemy: Node2D, dir: int) -> float:
	var rect := _get_body_rect(enemy)
	var cart := _get_rect()
	var dist: float = (cart.end.x + hop_margin - rect.position.x) if dir > 0 else (rect.end.x - (cart.position.x - hop_margin))
	return max(dist, 0.0)


func _get_body_rect(body: Node2D) -> Rect2:
	for child in body.get_children():
		if child is CollisionShape2D && !child.disabled && child.shape:
			var r: Rect2 = child.shape.get_rect()
			return Rect2(child.global_position + r.position, r.size)
	return Rect2(body.global_position - Vector2(4, 8), Vector2(8, 8))


func _update_hops(delta: float):
	for enemy in _hops.keys():
		var hop: Dictionary = _hops[enemy]
		if !is_instance_valid(enemy) || enemy.get("dead"):
			_hops.erase(enemy)
			continue
		hop.t = min(hop.t + delta, hop_time)
		var p: float = hop.t / hop_time
		var offset := Vector2(hop.dir * hop.dist * p, -hop_height * 4.0 * p * (1.0 - p)) #parabola, back to 0 at the end
		#relative to the cart: it keeps moving (it steps after this, like the rider's seat), so a fast cart
		#doesn't drive back into an enemy hopped off its front
		var collision = enemy.move_and_collide(offset - hop.offset + linear_velocity * delta)
		hop.offset = offset
		var blocked_sideways: bool = collision && abs(collision.get_normal().x) > 0.7
		if hop.t >= hop_time || blocked_sideways:
			_end_hop(enemy)


func _end_hop(enemy):
	var hop: Dictionary = _hops[enemy]
	_hops.erase(enemy)
	if !is_instance_valid(enemy): return
	enemy.remove_collision_exception_with(self)
	if hop.paused && !enemy.get("dead"):
		enemy.disabled = false
	enemy.velocity = Vector2.ZERO


#the player leaves the cart from inside it, so the collision exception stays until they've cleared it.
#A dead player keeps it (the death state ignores all carts).
func _update_former_rider():
	if !_former_rider: return
	if !is_instance_valid(_former_rider):
		_former_rider = null
		return
	if _former_rider.get("dead"):
		_former_rider = null
		return
	var feet: Vector2 = _former_rider.global_position
	var body := Rect2(feet.x - 6.0, feet.y - 15.0, 12.0, 15.0)
	if !body.intersects(_get_rect().grow(1.0)):
		_former_rider.remove_collision_exception_with(self)
		_former_rider = null


### SHOTS ###

var pushed_by := {} #"shot<id>"/"blast<id>" of bullets/grenade blasts that already pushed this cart

#pushes away from the face the shot hit, only as much as the hit is sideways: a side hit pushes fully, one
#landing on the top or a corner barely does. bullet.direction isn't reliable for this: bouncing shots
#(grenades, birdshot) only update their velocity, so after a wall reflects one its direction is wrong.
#hit_normal: the cart face's normal from the shot's own collision, when it has one (grenades).
func bullet_push(bullet, hit_normal := Vector2.ZERO):
	if !is_instance_valid(bullet) || !("knockback_strength" in bullet): return
	if _is_riders_shot(bullet): return
	if !_first_push_from(bullet): return

	var dir := 0.0
	var amount := 1.0 #how sideways the hit was
	if hit_normal != Vector2.ZERO:
		dir = -signf(hit_normal.x)
		amount = abs(hit_normal.normalized().x)
	else:
		var top := global_position.y + ground_hover
		var vertical_hit: bool = bullet.global_position.y < top + 2.0 || bullet.global_position.y > top + CART_SIZE.y - 2.0
		if vertical_hit: #landed on the top / hit from below: the sideways part of its travel
			var vel = bullet.get("velocity")
			if !(vel is Vector2) || vel == Vector2.ZERO:
				vel = bullet.direction
			dir = signf(vel.x)
			amount = abs(vel.normalized().x)
		else:
			dir = signf(get_center().x - bullet.global_position.x)
	pending_shot_velocity += dir * abs(bullet.knockback_strength) * shot_push_scale * amount


var explosion_push_scale := 4.0 #velocity added = grenade knockback_strength * this, at point blank
var explosion_min_falloff := 0.25 #push at the edge of the blast, as a fraction of point blank

#grenade blast: pushes away from the explosion, harder the closer the cart is. Called by GLauncher.
func explosion_push(grenade):
	if !is_instance_valid(grenade) || !("knockback_strength" in grenade): return
	if _is_riders_shot(grenade): return
	if !_first_push_from(grenade, "blast"): return

	var center: Vector2 = grenade.global_position
	var blast = grenade.get_node_or_null("ExplosionDetector")
	if blast: #stays where it went off while the grenade body keeps moving
		center = blast.global_position
	var radius := 32.0
	var blast_shape = grenade.get_node_or_null("ExplosionDetector/CollisionShape2D")
	if blast_shape && blast_shape.shape is CircleShape2D:
		radius = blast_shape.shape.radius
	var offset: Vector2 = get_center() - center
	if abs(offset.x) < 1.0: return #right above/below it, nothing to push sideways
	var falloff := clampf(1.0 - offset.length() / (radius + CART_SIZE.x / 2.0), explosion_min_falloff, 1.0)
	pending_shot_velocity += signf(offset.x) * abs(grenade.knockback_strength) * explosion_push_scale * falloff


#each bullet pushes once (grenades bounce and touch it again and again), each blast once
#the rider's own shots never push the cart they're riding
func _is_riders_shot(bullet) -> bool:
	return rider != null && !bullet.get("is_enemy_bullet")


func _first_push_from(source, kind := "shot") -> bool:
	var key := "%s%d" % [kind, source.get_instance_id()]
	if pushed_by.has(key): return false
	if pushed_by.size() > 32: #forget sources that are gone
		for old in pushed_by.keys():
			if !is_instance_id_valid(int(old.trim_prefix("shot").trim_prefix("blast"))): pushed_by.erase(old)
	pushed_by[key] = true
	return true


func _on_blocked(bullet, _body):
	#a grenade blast that the cart shields something from reports itself as its ExplosionDetector area
	if bullet is Area2D && bullet.get_parent() && "knockback_strength" in bullet.get_parent():
		explosion_push(bullet.get_parent())
	else:
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
	if is_grounded || crush_targets.is_empty() || linear_velocity.y < crush_min_fall_speed: return
	for t in crush_targets.duplicate():
		crush(t[0], t[1])
		crush_targets.erase(t)


func crush(type, target):
	if !is_instance_valid(target) || ignore_if_dead_player(target): return
	if spares(target): return
	match type:
		"player":
			if crush_players:
				f.pc().invincible = false
				target.hit(999, Vector2.ZERO, $CrushDetector)
		"enemy":
			if crush_enemies:
				target.hit(999, Vector2.ZERO, $CrushDetector)


#a cart never squishes or crushes its own rider (or one still climbing out), nor a player riding any other
#cart or who just left one (player Minecart state is_cart_immune()). Also used by the spikes
func spares(target) -> bool:
	if target == rider || target == _former_rider: return true
	if !is_instance_valid(target) || !target.is_in_group("Players"): return false
	var state = target.get_node_or_null("MovementManager/States/Minecart")
	return state != null && state.is_cart_immune()


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
