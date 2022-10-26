extends KinematicBody2D

class_name Bullet, "res://assets/Icon/BulletIcon.png"

const FIZZLE = preload("res://src/Effect/BulletFizzle.tscn")

var disabled = false
var gravity = 300

var damage
var f_range
var speed
var origin = Vector2.ZERO
var velocity = Vector2.ZERO
var direction = Vector2.ZERO

var break_method = "cut"
var default_area_collision = true
var default_body_collision = true
var is_enemy_bullet = false
var default_clear

onready var world = get_tree().get_root().get_node("World")


func _ready():
	if default_clear:
		var vis = VisibilityNotifier2D.new()
		add_child(vis)
		vis.connect("viewport_exited", self, "on_viewport_exit")

### HELPERS ###

func on_break(_method):
	if disabled: return
	print("destroyed bullet: " + name)
	fizzle("bullet")

func fizzle(type: String):
	var fizzle = FIZZLE.instance()
	fizzle.type = type.to_lower()
	world.get_node("Middle").add_child(fizzle)
	if has_node("End"): fizzle.position = $End.global_position
	else: fizzle.position = global_position
	queue_free()

### GETTERS ###

func get_rot(direction) -> float:
	var out = rad2deg(direction.rotated(PI).angle())
	return out

func get_blood_dir(body) -> Vector2:
	var out = Vector2(\
	floor((body.global_position.x - global_position.x)/10), \
	floor((body.global_position.y - global_position.y)/10))
	if out == null:
		printerr("ERROR: BULLET CANNOT GET BODY FOR BLOOD DIR CALCULATION")
		out = Vector2.ZERO
	return out

### SIGNALS ###

func on_viewport_exit(_viewport):
	queue_free()

func _on_CollisionDetector_body_entered(body):
	if not disabled and default_body_collision:
		#breakable
		if body.get_collision_layer_bit(8): 
			on_break(break_method)
		#enemy
		elif body.get_collision_layer_bit(1) and not is_enemy_bullet: 
			yield(get_tree(), "idle_frame") #why?
			body.hit(damage, get_blood_dir(body))
			queue_free()
		#player
		elif body.get_collision_layer_bit(0) and is_enemy_bullet: 
			body.hit(damage, get_blood_dir(body))
			queue_free()
		#world
		elif body.get_collision_layer_bit(3): 
			fizzle("world")
		#armor
		elif body.get_collision_layer_bit(5): 
			fizzle("armor")


#used for animated grass at the moment
func _on_CollisionDetector_area_entered(area):
	if not disabled and default_area_collision:
		if area.get_collision_layer_bit(8): #breakable
			on_break(break_method)
		elif area.get_collision_layer_bit(3): #world
			fizzle("world")
		elif area.get_collision_layer_bit(5): #armor
			fizzle("armor")
