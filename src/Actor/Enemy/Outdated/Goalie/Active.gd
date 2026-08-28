extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	em.velocity = em.calc_velocity(Vector2.ZERO)
	em.move_and_slide()
	em.update_detector_position()
	if !em.target:
		sm.change_state("Idle")
	elif em.player_in_jump_zone && inp.pressed("jump"):
		sm.change_state("Rise")

func enter():
	ap.play("Active")

func exit():
	pass
