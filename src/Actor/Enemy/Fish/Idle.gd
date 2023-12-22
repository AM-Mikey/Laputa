extends State

#var state_name = "Idle"

@onready var ap = get_parent().get_parent().get_node("AnimationPlayer")
@onready var em = get_parent().get_parent()

func state_process():
	var collision = em.get_node("RayCast2D").get_collider()
	if collision != null:
		if collision.get_collision_layer_value(1): #player
			print("got target")
			sm.change_state("attack")

func enter():
	if em.can_move_x:
		sm.change_state("swim")
	else:
		get_parent().get_parent().get_node("AnimationPlayer").play("Idle")
	
func exit():
	pass
