extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	var player = f.pc()
	if player:
		em.look_dir.x = signf(player.global_position.x - em.global_position.x)
	em.velocity = em.calc_velocity(Vector2.ZERO)
	em.move_and_slide()
	em.update_detector_position()
	if em.target:
		sm.change_state("Active")

func enter():
	ap.play("Idle")


func exit():
	pass
