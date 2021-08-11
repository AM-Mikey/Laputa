extends KinematicBody2D

class_name Bullet, "res://assets/Icon/BulletIcon.png"

const STARPOP = preload("res://src/Effect/StarPop.tscn")
const RICOCHET = preload("res://src/Effect/Ricochet.tscn")



var disabled = false
var gravity = 300
var damage



func _fizzle_from_world():
	#print("fizzle from world") 
	var ricochet = RICOCHET.instance()
	get_tree().get_root().get_node("World/Back").add_child(ricochet)
	if has_node("End"): ricochet.position = $End.global_position
	else: ricochet.position = global_position
	
	queue_free()

func _fizzle_from_range():
	#print("fizzle from range")
	var star_pop = STARPOP.instance()
	get_tree().get_root().get_node("World/Back").add_child(star_pop)
	star_pop.position = global_position
	queue_free()

func _on_VisibilityNotifier2D_viewport_exited(viewport):
	queue_free()

