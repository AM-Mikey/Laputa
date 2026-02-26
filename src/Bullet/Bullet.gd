@icon("res://assets/Icon/BulletIcon.png")
extends CharacterBody2D

class_name Bullet

const FIZZLE_DISTANCE = preload("res://src/Effect/BulletFizzleDistance.tscn")
const FIZZLE_WORLD = preload("res://src/Effect/BulletFizzleWorld.tscn")
const FIZZLE_ARMOR = preload("res://src/Effect/BulletFizzleArmor.tscn")

var gravity = 300

var damage = 0
var f_range
var f_time
var speed
var spread_degrees
var origin = Vector2.ZERO
var direction = Vector2.ZERO
var instant_fizzle = true

var break_method = "cut"
var is_enemy_bullet = false

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

func _on_physics_process(delta): #for children
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
	var fizzle
	match type:
		"range":
			fizzle = FIZZLE_DISTANCE.instantiate()
			fizzle.direction = direction
		"world":
			fizzle = FIZZLE_WORLD.instantiate()
		"armor":
			fizzle = FIZZLE_ARMOR.instantiate()


	w.get_node("Middle").add_child(fizzle)
	fizzle.position = $End.global_position if has_node("End") else global_position
	if instant_fizzle and not is_enemy_bullet:
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
	queue_free()

func instant_fizzle_check():
	instant_fizzle = true
	visible = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	instant_fizzle = false
	visible = true



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



### SIGNALS ###

func _on_CollisionDetector_body_entered(body):
	if body is TileMapLayer:
		if body.tile_set.get_physics_layer_collision_layer(0) == 8: #world (layer value)
			do_fizzle("world")

	else: #not TileMapLayer
		#breakable
		if body.get_collision_layer_value(9):
			on_break(break_method)
		#armor
		elif body.get_collision_layer_value(6):
			do_fizzle("armor")


func _on_CollisionDetector_area_entered(area):
	if area.get_collision_layer_value(18): #enemyhurt
		area.get_parent().hit(damage, get_blood_dir(area.get_parent()))
		queue_free()
	elif area.get_collision_layer_value(17): #playerhurt
		area.get_parent().hit(damage, get_blood_dir(area.get_parent()))
		queue_free()
	elif area.get_collision_layer_value(9): #breakable
		area.get_parent().on_break(break_method)
		#on_break(break_method) produced two fizzle particles so instead do:
		queue_free()
	elif area.get_collision_layer_value(4): #world
		do_fizzle("world")
	elif area.get_collision_layer_value(6): #armor
		print("armor")
		do_fizzle("armor")
