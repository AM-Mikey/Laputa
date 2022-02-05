extends State

onready var em = get_parent().get_parent()
onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if em.position.y <= em.jump_pos.y:
		sm.change_state("fall")
	em.velocity = em.move_and_slide(get_velocity())


func get_velocity() -> Vector2:
	var out = em.velocity
	out.y = em.speed.y * em.move_dir.y
	return out



func enter():
	ap.play("Rise")
	em.move_dir = Vector2.UP

func exit():
	em.velocity = Vector2.ZERO
