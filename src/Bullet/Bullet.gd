extends KinematicBody2D

class_name Bullet, "res://assets/Icon/BulletIcon.png"

const STARPOP = preload("res://src/Effect/StarPop.tscn")
const RICOCHET = preload("res://src/Effect/Ricochet.tscn")



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



func _fizzle_from_world():
	#print("fizzle from world") 
	var ricochet = RICOCHET.instance()
	get_tree().get_root().get_node("World/Middle").add_child(ricochet)
	if has_node("End"): ricochet.position = $End.global_position
	else: ricochet.position = global_position
	
	queue_free()

func _fizzle_from_range():
	#print("fizzle from range")
	var star_pop = STARPOP.instance()
	get_tree().get_root().get_node("World/Middle").add_child(star_pop)
	star_pop.position = global_position
	queue_free()

func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()


func _on_CollisionDetector_body_entered(body):
	
	if not disabled and default_body_collision:
		if body.get_collision_layer_bit(8): #breakable
					body.on_break(break_method)
					if body.get_collision_layer_bit(3): #world
						_fizzle_from_world()

		elif body.get_collision_layer_bit(1): #enemy
			yield(get_tree(), "idle_frame")
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
			queue_free()
		elif body.get_collision_layer_bit(3): #world
			_fizzle_from_world()


#used for animated grass at the moment
func _on_CollisionDetector_area_entered(area):
	if not disabled and default_area_collision:
		if area.get_collision_layer_bit(8): #breakable
				area.on_break(break_method)
		elif area.get_collision_layer_bit(3): #world
			_fizzle_from_world()
