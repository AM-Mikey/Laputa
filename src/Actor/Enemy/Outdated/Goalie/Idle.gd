extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if em.player_in_active_zone:
		get_parent().change_state("Active")

func enter():
	ap.play("Idle")

func exit():
	pass
