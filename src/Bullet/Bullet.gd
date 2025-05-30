@icon("res://assets/Icon/BulletIcon.png")
extends CharacterBody2D

class_name Bullet

const FIZZLE = preload("res://src/Effect/BulletFizzle.tscn")

var disabled = false
var gravity = 300

var damage = 0
var f_range
var f_time
var speed
var origin = Vector2.ZERO
#var _velocity = Vector2.ZERO
var direction = Vector2.ZERO
var instant_fizzle = true

var break_method = "cut"
var is_enemy_bullet = false

@onready var world = get_tree().get_root().get_node("World")



### HELPERS ###

func setup_vis_notifier():
	var vis = VisibleOnScreenNotifier2D.new()
	add_child(vis)
	vis.connect("screen_exited", Callable(self, "_on_screen_exit"))

func on_break(_method):
	if disabled: return
	print("destroyed bullet: " + name)
	do_fizzle("bullet")

func do_fizzle(type: String):
	var fizzle = FIZZLE.instantiate()
	fizzle.type = type.to_lower()
	world.get_node("Middle").add_child(fizzle)
	
	fizzle.position = $End.global_position if has_node("End") else global_position
	if instant_fizzle and not is_enemy_bullet:
		print("WARNING: Bullet instantly fizzled")
		fizzle.position = world.get_node("Juniper").guns.get_child(0).get_node("Muzzle").global_position
	queue_free()

func instant_fizzle_check():
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

func _on_screen_exit(): #TODO: bullets that start offscreen are not cleared
	print("cleared offscreen bullet")
	queue_free()

func _on_CollisionDetector_body_entered(body):
	if disabled: return
	if body is TileMap:
		if body.tile_set.get_physics_layer_collision_layer(0) == 8: #world (layer value)
			do_fizzle("world")
	
	else: #not tilemap
		#breakable
		if body.get_collision_layer_value(9): 
			on_break(break_method)
		#player
		elif body.get_collision_layer_value(1) and is_enemy_bullet:
			body.get_parent().hit(damage, get_blood_dir(body))
			queue_free()
		#armor
		elif body.get_collision_layer_value(6):
			do_fizzle("armor")


func _on_CollisionDetector_area_entered(area):
	if disabled: return
	
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
		
