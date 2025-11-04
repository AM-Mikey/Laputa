extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	em.set_velocity(calc_velocity())
	em.move_and_slide()
	em.velocity = em.velocity

	if em.velocity.y == 0:
		sm.change_state("Active")
		return


func calc_velocity() -> Vector2:
	var out = em.velocity
	out.y += em.gravity * get_physics_process_delta_time()
	return out



func enter():
	ap.play("Fall")

func exit():
	pass
	#em.velocity = Vector2.ZERO
