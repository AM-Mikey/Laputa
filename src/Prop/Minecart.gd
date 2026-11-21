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

const ICON = preload("res://assets/Prop/MinecartIcon.png")

signal blocked(bullet, body) #emitted by Bullet.armor_check()

@export var can_fall_off_ledges := true
@export var crush_players := true
@export var crush_enemies := true
@export var squish_enemies := true #enemies the cart drives into a wall/ceiling
@export var squish_players := true #same for the player

var push_max_speed := 70.0 #keep below player walk speed (90) so the player stays in contact
var push_start_accel := 40.0 #accel when starting from rest, feels heavy
var push_full_accel := 140.0 #accel once rolling
var ground_friction := 90.0 #decel when nothing is pushing, controls how far it coasts
var slope_friction := 30.0 #lower on slopes so gravity always wins and it never sits stuck (and unpushable) on one
var push_reach := 2.0 #px gap between player and cart that still counts as touching
var push_grace_time := 0.12 #keeps the push going through the player's contact stutter
var max_roll_speed := 240.0 #cap for long slopes

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
	_measure_grade_support()
	sprite_base_pos = $Sprite2D.position + Vector2(0, ground_hover) #physics hovers above the floor, the sprite shouldn't
	carry_base_pos = $CarryDetector/CollisionShape2D.position + Vector2(0, ground_hover)
	_build_grade_shapes()
	_apply_look()
	blocked.connect(_on_blocked)
	w.emit_signal("finished_spawn_entities_step")


func _physics_process(delta):
	_update_push(delta)
	_update_crush()
	_update_carry(delta)
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

	var k := 0.0
	var ground_y := 0.0
	if !back.is_empty() && !front.is_empty():
		k = (front.position.y - back.position.y) / (front.position.x - back.position.x)
		ground_y = (front.position.y + back.position.y) / 2.0
	elif !back.is_empty() || !front.is_empty():
		var hit: Dictionary = back if !back.is_empty() else front
		if _is_slope(hit.normal):
			k = -hit.normal.x / hit.normal.y
		ground_y = hit.position.y + k * (cx - hit.position.x)
	else:
		return {}

	#going over a peak the line between the wheels dips below it, rest on the peak instead
	var middle := _ray(state, cx, from_y, to_y)
	if !middle.is_empty():
		ground_y = min(ground_y, middle.position.y)

	if abs(k) < 0.02: k = 0.0
	return {"y": ground_y, "k": k, "floor_vx": _get_floor_velocity_x(back, front)}


func _ray(state: PhysicsDirectBodyState2D, x: float, from_y: float, to_y: float) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, to_y), collision_mask, [get_rid()])
	return state.get_space_state().intersect_ray(query)


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
	$CarryDetector/CollisionShape2D.position = carry_base_pos + offset


### CARRYING ###

#props resting on top get dragged toward the cart's speed. Anything that holds them back harder
#(a wall, a ceiling block) just stops them and the cart rolls out from under.
func _update_carry(delta):
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


### ANIMATION ###

func _update_animation():
	var anim: String = GRADE_ANIM[grade]
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


### SHOTS ###

var pushed_by := {} #"shot<id>"/"blast<id>" of bullets/grenade blasts that already pushed this cart

#pushes away from the face the shot hit, only as much as the hit is sideways: a side hit pushes fully, one
#landing on the top or a corner barely does. bullet.direction isn't reliable for this: bouncing shots
#(grenades, birdshot) only update their velocity, so after a wall reflects one its direction is wrong.
#hit_normal: the cart face's normal from the shot's own collision, when it has one (grenades).
func bullet_push(bullet, hit_normal := Vector2.ZERO):
	if !is_instance_valid(bullet) || !("knockback_strength" in bullet): return
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
