extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
#	if em.velocity.y >= 0:
#		ap.play("Fall")
	if em.is_on_floor():
		sm.change_state("Active")

	em.set_velocity(calc_velocity())
	em.move_and_slide()
	em.velocity = em.velocity


func calc_velocity() -> Vector2:
	var out = em.velocity
	
	out.y += em.gravity * get_physics_process_delta_time()
	if em.move_dir.y < 0:
		out.y = em.speed.y
	
	return out

func enter():
	ap.play("Rise")

func exit():
	em.velocity = Vector2.ZERO
