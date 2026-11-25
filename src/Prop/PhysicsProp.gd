@icon("res://assets/Icon/PhysicsPropIcon.png")
extends RigidBody2D
class_name PhysicsProp

var rng = RandomNumberGenerator.new()
var inspect_time = 0.2
var base_gravity_scale := 1.0
var water_gravity_scale := 0.5
var spent = false

var is_in_water = false: set = set_is_in_water
@export var do_bubble: bool = false
var is_wind_affected := false
var wind_areas_inside := []

@export var editor_hidden = false
@export var id: String

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	_add_prop_collision_exceptions()
	setup()

#props in "NoPropCollision" (chests, save disk, ammo refill) have physics against the level but shouldn't
#push or be pushed by other props. Carts and breakblocks are on the world layer (so things can stand on
#them), which masks can't tell apart from tiles, so the pairs are excluded here instead. Done from both
#sides so it works whichever one spawns first.
func _add_prop_collision_exceptions():
	var others := []
	if is_in_group("NoPropCollision"):
		others = get_tree().get_nodes_in_group("Minecarts") + get_tree().get_nodes_in_group("BreakBlocks")
	elif is_in_group("Minecarts") || is_in_group("BreakBlocks"):
		others = get_tree().get_nodes_in_group("NoPropCollision")
	for other in others:
		if other != self && other is PhysicsBody2D:
			add_collision_exception_with(other)

func setup(): #for children
	pass

func set_is_in_water(val):
	gravity_scale = base_gravity_scale if !val else water_gravity_scale
	is_in_water = val

func apply_wind():
	if !is_wind_affected: return
	var strongest_by_dir := {}

	for area in wind_areas_inside:
		var key: Vector2 = area.wind_dir
		if not strongest_by_dir.has(key) or area.speed > strongest_by_dir[key].speed:
			strongest_by_dir[key] = area

	for strong_area in strongest_by_dir.values():
		apply_central_force(strong_area.wind_dir * strong_area.speed)

const SUPPORT_SIZE := Vector2(16, 16) #props are 16x16 with their origin at the top left
var _support_shape: RectangleShape2D

#bodies holding this prop up: anything solid (world, ssp, other props, carts) in a thin strip just under
#its bottom. Players/enemies aren't in the mask, so a prop sitting on someone's head isn't "held up".
func get_supporters() -> Array:
	if !_support_shape:
		_support_shape = RectangleShape2D.new()
		_support_shape.size = Vector2(SUPPORT_SIZE.x - 2.0, 2.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _support_shape
	query.transform = Transform2D(0.0, global_position + Vector2(SUPPORT_SIZE.x / 2.0, SUPPORT_SIZE.y + 1.0))
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var out := []
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 8):
		if hit.collider && !out.has(hit.collider):
			out.append(hit.collider)
	return out

#rigid bodies rest sunk ~0.1px into what they stand on, which leaves a step the player can't walk up from
#this prop onto a tile or cart. Call from _integrate_forces to sit exactly on a flat surface instead.
var carry_friction := 400.0 #px/s^2, how hard a settled prop is dragged along by the body it sits on
var settle_friction := 1.0 #friction coefficient of a settled prop on still ground (decel = gravity * this)
var breakaway_speed := 0.0 #static friction, px/s: weaker knocks don't move it from rest (0 = off)
var _at_rest := false
var _rest_x := 0.0

func settle_on_ground(state: PhysicsDirectBodyState2D, size := SUPPORT_SIZE, inset := 2.0):
	var was_at_rest := _at_rest
	_at_rest = false
	if abs(state.linear_velocity.y) > 20.0: return #falling or launched, not resting
	var origin := state.transform.origin
	var bottom := origin.y + size.y
	var space := state.get_space_state()
	var highest := INF
	var lowest := -INF
	var floor_vy := 0.0
	var floor_vx := 0.0
	var on_body := false
	for x in [inset, size.x - inset]:
		var query := PhysicsRayQueryParameters2D.create(Vector2(origin.x + x, bottom - 4.0), Vector2(origin.x + x, bottom + 0.5), collision_mask, [get_rid()])
		var hit := space.intersect_ray(query)
		if hit.is_empty(): continue #partly over an edge, settle on whatever is under the rest of it
		highest = min(highest, hit.position.y)
		lowest = max(lowest, hit.position.y)
		if hit.collider is RigidBody2D: #riding a cart/box, move with it
			floor_vy = hit.collider.linear_velocity.y
			floor_vx = hit.collider.linear_velocity.x
			on_body = true
		elif hit.collider is StaticBody2D && hit.collider.constant_linear_velocity != Vector2.ZERO: #conveyor belt
			floor_vx = hit.collider.constant_linear_velocity.x
			on_body = true
	if highest == INF: return #nothing under it
	if lowest - highest > 0.5 || abs(highest - bottom) > 0.5: return #not flat, or not resting on it
	var xform := state.transform
	xform.origin.y = highest - size.y
	state.transform = xform
	#gravity would otherwise keep building up and sink it again between snaps
	if state.linear_velocity.y > floor_vy:
		state.linear_velocity.y = floor_vy
	#sitting exactly on top leaves no contact pressure, so friction does nothing: apply it by hand. Moving
	#bodies/belts drag it along (same strength as a cart carrying it), still ground slows it like normal
	#friction would (gravity * friction 1). Anything pushing harder still knocks it off / slides it.
	var friction := carry_friction if on_body else state.total_gravity.y * gravity_scale * settle_friction
	state.linear_velocity.x = move_toward(state.linear_velocity.x, floor_vx, friction * state.step)

	#static friction: resting on still ground, a knock that would give it less than breakaway_speed doesn't
	#move it at all (undo the creep the contact already caused). A harder hit breaks it loose and it slides.
	if !on_body && breakaway_speed > 0.0:
		if was_at_rest && abs(state.linear_velocity.x) < breakaway_speed:
			state.linear_velocity.x = 0.0
			xform.origin.x = _rest_x
			state.transform = xform
		if state.linear_velocity.x == 0.0:
			_at_rest = true
			_rest_x = xform.origin.x

func is_supported() -> bool:
	return !get_supporters().is_empty()

#true when resting on a minecart, directly or on top of a stack of props that is
func rests_on_minecart(depth := 4) -> bool:
	if depth <= 0: return false
	for cart in get_tree().get_nodes_in_group("Minecarts"):
		if cart != self && cart.has_method("is_carrying") && cart.is_carrying(self):
			return true
	for body in get_supporters():
		if body.is_in_group("Minecarts"):
			return true
		if body is PhysicsProp && body.rests_on_minecart(depth - 1):
			return true
	return false

#props don't collide with players/enemies, they step out of the way themselves. One that this prop has
#ended up deep inside (area = the prop's shape shrunk a few px) and that can't move away from it is
#pinned against a wall or ceiling, so it gets squished.
func squish_pinned(area: Area2D, source: Node2D, squish_enemies := true, squish_players := true):
	var middle: Vector2 = area.get_child(0).global_position
	for body in area.get_overlapping_bodies():
		var mover: Node = null #the body that actually moves and collides with the world
		if body.get_collision_layer_value(1):
			if !squish_players: continue
			mover = body.get_parent() #PlayerLayerBody is a child of the player
		elif body.get_collision_layer_value(2):
			if !squish_enemies: continue
			mover = body
		if !(mover is CharacterBody2D) || !mover.has_method("hit"): continue
		if ignore_if_dead_player(mover): continue
		if spares(mover): continue
		if !mover.get_collision_mask_value(4): continue #passes through world, can't be pinned
		#test along the main axis only, so a short body beside the prop doesn't "hit" the floor
		var away: Vector2 = _get_body_center(mover) - middle
		var dir := Vector2(sign(away.x), 0.0) if abs(away.x) >= abs(away.y) else Vector2(0.0, sign(away.y))
		if dir == Vector2.ZERO: dir = Vector2.UP
		if mover.test_move(mover.global_transform, dir * 2.0):
			if mover.is_in_group("Players"):
				mover.invincible = false
			mover.hit(999, Vector2.ZERO, source)

#bodies this prop never squishes or crushes (overridden by Minecart for riders)
func spares(_target) -> bool:
	return false

#a player that's already dead is left alone, and stops colliding with this prop so the death
#bounce doesn't get stuck inside it and crushed over and over. Players don't revive (a new one spawns).
func ignore_if_dead_player(target) -> bool:
	if !is_instance_valid(target) || !target.is_in_group("Players") || !target.get("dead"):
		return false
	if target is PhysicsBody2D:
		target.add_collision_exception_with(self)
	return true

func _get_body_center(body: Node2D) -> Vector2:
	for child in body.get_children():
		if child is CollisionShape2D || child is CollisionPolygon2D:
			return child.global_position
	return body.global_position

func get_center() -> Vector2:
	return $CollisionShape2D.global_position
