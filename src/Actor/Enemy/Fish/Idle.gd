extends Node

var state_name = "Idle"

onready var ap = get_parent().get_parent().get_node("AnimationPlayer")
onready var em = get_parent().get_parent()

func state_process():
	var collision = em.get_node("RayCast2D").get_collider()
	if collision != null:
		if collision.get_collision_layer_bit(0): #player
			print("got target")
			em.change_state(em.states["attack"])

func enter():
	if em.can_move_x:
		em.change_state(em.states["swim"])
	else:
		get_parent().get_parent().get_node("AnimationPlayer").play("Idle")
	
func exit():
	pass
