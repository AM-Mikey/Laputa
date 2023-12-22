extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if em.position.y <= em.jump_pos.y:
		sm.change_state("fall")
	em.set_velocity(calc_velocity())
	em.move_and_slide()
	em.velocity = em.velocity


func calc_velocity() -> Vector2:
	var out = em.velocity
	out.y = em.speed.y * em.move_dir.y
	return out



func enter():
	ap.play("Rise")
	em.move_dir = Vector2.UP

func exit():
	em.velocity = Vector2.ZERO
