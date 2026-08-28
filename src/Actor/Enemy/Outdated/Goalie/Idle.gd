extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if em.target:
		sm.change_state("Active")

func enter():
	em.update_detector_position()
	ap.play("Idle")

func exit():
	pass
