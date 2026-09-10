@icon("res://assets/Icon/BulletIcon.png")
extends CharacterBody2D

class_name Bullet

const FIZZLE_DISTANCE = preload("res://src/Effect/BulletFizzleDistance.tscn")
const FIZZLE_WORLD = preload("res://src/Effect/BulletFizzleWorld.tscn")
const FIZZLE_ARMOR = preload("res://src/Effect/BulletFizzleArmor.tscn")

@export var base_gravity := 300.0
@export var water_gravity := 150.0
@export var damage := 0.0
@export var camera_recoil_distance := 0.0
@export var camera_recoil_hit_distance : float
@export var camera_recoil_wall_distance : float
@export var camera_recoil_curve : Curve
@export var camera_recoil_time := 0.1

@onready var gravity := water_gravity if is_in_water else base_gravity

var f_range
var f_time
var speed
var spread_degrees
var knockback_strength := 0.0
var origin = Vector2.ZERO
var direction = Vector2.ZERO
var instant_fizzle := true
var already_fizzle := false

var break_method = "cut"
@export var is_water_affected := false
@export var is_wind_affected := false
@export var is_enemy_bullet := false
@export var piercing := false

var wind_areas_inside := []
var is_in_water := false:
	set(val):
		if is_water_affected:
			gravity = water_gravity if val else base_gravity
			on_is_in_water_change(is_in_water, val)
		is_in_water = val


@onready var w = get_tree().get_root().get_node("World")
@onready var rng = RandomNumberGenerator.new()

const TIMEOUT_TIME: float = 60.0
const level_exit_safe_distance: float = 512.0



func _ready():
	print("doing ready")
	setup_timeout()
	if f.pc():
		if camera_recoil_distance > 0.0:
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_distance, camera_recoil_time, camera_recoil_curve)
		else: #do simple vibrate instead
			oup.vibrate_impulse(0.1, 0.075)
	setup()

func setup(): #for children
	pass

func _physics_process(delta):
	level_exit_check()
	_on_physics_process(delta)
	apply_wind()

func _on_physics_process(_delta): #for children
	pass

func apply_wind():
	if !is_wind_affected: return
	var strongest_by_dir := {}

	for area in wind_areas_inside:
		var key: Vector2 = area.wind_dir
		if not strongest_by_dir.has(key) or area.speed > strongest_by_dir[key].speed:
			strongest_by_dir[key] = area

	for strong_area in strongest_by_dir.values():
		if is_on_floor() && (strong_area.wind_dir == Vector2.DOWN || (strong_area.wind_dir == Vector2.UP && strong_area.speed <= 4.0)):
			continue
		velocity += strong_area.wind_dir * strong_area.speed

func setup_timeout():
	await get_tree().create_timer(TIMEOUT_TIME, false, true).timeout
	print("freed bullet via timeout")
	queue_free()

func level_exit_check():
	var level_limiter = w.current_level.get_node("LevelLimiter")
	var safe_rect = Rect2(level_limiter.global_position, level_limiter.size)
	safe_rect = safe_rect.grow(level_exit_safe_distance)
	if (!safe_rect.has_point(global_position)):
		print("freed bullet via level bounds")
		queue_free()

func on_break(_method):
	print("destroyed bullet: " + name)
	do_fizzle("bullet")

func do_fizzle(type: String):
	#print("fizzling bullet")
	if already_fizzle: return

	var fizzle
	match type:
		"range":
			fizzle = FIZZLE_DISTANCE.instantiate()
			fizzle.direction = direction
		"world":
			fizzle = FIZZLE_WORLD.instantiate()
		"armor":
			fizzle = FIZZLE_ARMOR.instantiate()
		"bullet":
			fizzle = FIZZLE_ARMOR.instantiate()

	fizzle.position = $End.global_position if has_node("End") else global_position
	if instant_fizzle and not is_enemy_bullet and f.pc():
		var gun = f.pc().guns.get_child(0)
		var gun_center = gun.global_position
		var space_state = get_world_2d().direct_space_state
		# use global coordinates, not local to node
		var query = PhysicsRayQueryParameters2D.create(gun_center, fizzle.position)
		# Bullet should have its collison mask set accurately to what it intends to collide with
		# collision mask: World (bit 3), Armor (bit 5), Breakable (bit 8)
		# This is done so the raycast doesn't collide with the player or anything else!
		query.collision_mask = 1<<3 | 1<<5 | 1<<8
		# If the raycast appears already inside another body (e.g. a block), we should still consider it,
		# otherwise the fizzle will appear incorrectly on the other side of the block
		query.hit_from_inside = true
		var result = space_state.intersect_ray(query)
		if result:
			fizzle.position = result.position
	w.player_front.add_child(fizzle)
	already_fizzle = true
	queue_free()

func instant_fizzle_check():
	instant_fizzle = true
	visible = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	instant_fizzle = false
	visible = true

func on_is_in_water_change(old_val, val):
	pass

### GETTERS ###

func get_rot(dir) -> float:
	var out = rad_to_deg(dir.rotated(PI).angle())
	return out

func get_blood_dir(body) -> Vector2: #TODO this update changed knockback dir calculation, try calculating seperately
	var out: Vector2
	var collision_shape
	if body.has_node("CollisionShape2D"):
		collision_shape = body.get_node("CollisionShape2D")
	else:
		collision_shape = body.get_child(0)
	var body_center = collision_shape.global_position

	out = Vector2(
		(body_center.x - global_position.x),
		(body_center.y - global_position.y)).normalized()
	if out == null:
		printerr("ERROR: BULLET CANNOT GET BODY FOR BLOOD DIR CALCULATION")
		out = Vector2.ZERO
	return out

### UTILITY ###
func armor_check(body) -> bool:
	if body.block_dir != Vector2.ZERO:
		var block_dir = body.block_dir * body.scale
		var valid_collision_shape = null
		for child in body.get_children():
			if child is CollisionShape2D and !child.disabled and child.shape is RectangleShape2D:
				valid_collision_shape = child
				break
		if valid_collision_shape:
			var collision_rect_center = valid_collision_shape.global_position
			match block_dir:
				Vector2.LEFT:
					if global_position.x <= collision_rect_center.x:
						body.blocked.emit(self, body)
						return true
				Vector2.RIGHT:
					if global_position.x >= collision_rect_center.x:
						body.blocked.emit(self, body)
						return true
				Vector2.DOWN:
					if global_position.y >= collision_rect_center.y:
						body.blocked.emit(self, body)
						return true
				Vector2.UP:
					if global_position.y <= collision_rect_center.y:
						body.blocked.emit(self, body)
						return true
		return false
	else:
		body.blocked.emit(self, body)
		return true


### SIGNALS ###

func _on_CollisionDetector_body_entered(body):
	if body is TileMapLayer:
		if body.tile_set.get_physics_layer_collision_layer(0) == 8: #world (layer value)
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			do_fizzle("world")

	else: #not TileMapLayer
		#breakable
		if body.get_collision_layer_value(9):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
			on_break(break_method)
		#armor
		elif body.get_collision_layer_value(6):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			do_fizzle("armor")
		#Movable platform
		if body.get_collision_layer_value(4):
			if f.pc(): #and camera gun recoil is true
				f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
			do_fizzle("world")


func _on_CollisionDetector_area_entered(area): #TODO: double check breakable piercing
	if area.get_collision_layer_value(18): #enemyhurt
		var blood_dir = get_blood_dir(area.get_parent())
		area.get_parent().hit(damage, blood_dir, blood_dir, knockback_strength)
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
		if !piercing:
			queue_free()
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(damage, get_blood_dir(area.get_parent()))
		if !piercing:
			queue_free()
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break(break_method)
		#on_break(break_method) produced two fizzle particles so instead do:
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_hit_distance, camera_recoil_time, camera_recoil_curve)
		#not neccesary to queue free as fizzle does this
	elif area.get_collision_layer_value(4): #world
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
		do_fizzle("world")
	elif area.get_collision_layer_value(6): #armor
		if f.pc(): #and camera gun recoil is true
			f.pc().get_node("PlayerCamera").impulse(f.pc().shoot_dir * -1, camera_recoil_wall_distance, camera_recoil_time, camera_recoil_curve)
		do_fizzle("armor")
