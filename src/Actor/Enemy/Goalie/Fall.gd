extends State

onready var em = get_parent().get_parent()
onready var ap = em.get_node("AnimationPlayer")

func state_process():
	em.velocity = em.move_and_slide(get_velocity())
	
	if em.velocity.y == 0:
		sm.change_state("Active")


func get_velocity() -> Vector2:
	var out = em.velocity
	out.y += em.gravity * get_physics_process_delta_time()
	return out



func enter():
	ap.play("Fall")

func exit():
	pass
	#em.velocity = Vector2.ZERO
