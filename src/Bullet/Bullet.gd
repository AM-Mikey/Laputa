@icon("res://assets/Icon/BulletIcon.png")
extends CharacterBody2D

class_name Bullet

const FIZZLE_DISTANCE = preload("res://src/Effect/BulletFizzleDistance.tscn")
const FIZZLE_WORLD = preload("res://src/Effect/BulletFizzleWorld.tscn")
const FIZZLE_ARMOR = preload("res://src/Effect/BulletFizzleArmor.tscn")

@export var base_gravity := 300.0
@export var water_gravity := 150.0
@export var damage := 0.0

@onready var gravity := water_gravity if is_in_water else base_gravity

var f_range
var f_time
var speed
var spread_degrees
var origin = Vector2.ZERO
var direction = Vector2.ZERO
var instant_fizzle := true
var already_fizzle := false

var break_method = "cut"
@export var is_water_affected := false
@export var is_wind_affected := false
@export var is_enemy_bullet := false

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
	setup_timeout()
	setup()

func setup(): #for children
	pass

func _physics_process(delta):
	level_exit_check()
	_on_physics_process(delta)

func _on_physics_process(_delta): #for children
	pass

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
	w.get_node("Middle").add_child(fizzle)
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
			do_fizzle("world")

	else: #not TileMapLayer
		#armor
		if body.get_collision_layer_value(6):
			if armor_check(body):
				do_fizzle("armor")
		#breakable
		elif body.get_collision_layer_value(9):
			on_break(break_method)
		#Movable platform
		elif body.get_collision_layer_value(4):
			do_fizzle("world")


func _on_CollisionDetector_area_entered(area):
	if area.get_collision_layer_value(6): #armor
		do_fizzle("armor")
	elif area.get_collision_layer_value(18): #enemyhurt
		if !is_queued_for_deletion():
			area.get_parent().hit(damage, get_blood_dir(area.get_parent()), $PlayerCollisionDetector)
			queue_free()
	elif area.get_collision_layer_value(17): #playerhurt
		if !is_queued_for_deletion():
			area.get_parent().hit(damage, get_blood_dir(area.get_parent()), $PlayerCollisionDetector)
			queue_free()
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break(break_method)
		#on_break(break_method) produced two fizzle particles so instead do:
		queue_free()
	elif area.get_collision_layer_value(4): #world
		do_fizzle("world")
