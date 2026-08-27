extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if !em.player_in_active_zone:
		get_parent().change_state("Idle")

func enter():
	ap.play("Active")

func exit():
	pass
