extends Node

var state_name = "Swim"

onready var em = get_parent().get_parent()
onready var ap = em.get_node("AnimationPlayer")
onready var rc = em.get_node("RayCast2D")


func state_process():
	rc.position.x = 4 * em.move_dir.x
	
	var collision = rc.get_collider()
	if collision != null:
		if collision.get_collision_layer_bit(0): #player
			print("got target")
			em.change_state(em.states["attack"])
	
	
	if em.position.x < em.start_pos.x + em.x_min * 16:
		em.move_dir = Vector2.RIGHT
	if em.position.x > em.start_pos.x + em.x_max * 16:
		em.move_dir = Vector2.LEFT
	
	em.velocity = em.move_and_slide(get_velocity())


func get_velocity() -> Vector2:
	var out = em.velocity
	
	out.x = em.speed.x * em.move_dir.x
	
	return out

func enter():
	em.move_dir = Vector2.LEFT
	ap.play("Idle")

func exit():
	rc.position = Vector2.ZERO
	em.move_dir = Vector2.ZERO
	em.velocity = Vector2.ZERO
