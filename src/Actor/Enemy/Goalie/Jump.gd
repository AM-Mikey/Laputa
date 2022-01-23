extends State

onready var em = get_parent().get_parent()
onready var ap = em.get_node("AnimationPlayer")

func state_process():
#	if em.velocity.y >= 0:
#		ap.play("Fall")
	if em.is_on_floor():
		sm.change_state("Active")

	em.velocity = em.move_and_slide(get_velocity())


func get_velocity() -> Vector2:
	var out = em.velocity
	
	out.y += em.gravity * get_physics_process_delta_time()
	if em.is_on_floor():
		out.y = em.speed.y * -1
	
	return out

func enter():
	ap.play("Rise")

func exit():
	em.velocity = Vector2.ZERO
