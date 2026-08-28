extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if !em.target:
		sm.change_state("Idle")
	elif em.player_in_jump_zone and inp.pressed("jump"):
		sm.change_state("Rise")

func enter():
	em.update_detector_position()
	ap.play("Active")

func exit():
	pass
