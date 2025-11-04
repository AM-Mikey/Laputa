extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if not ap.is_playing():
		sm.change_state("Fall")
		return



func enter():
	ap.play("Kick")
	em.target.hit(em.kick_damage, Vector2(sign(em.target.global_position.x - em.global_position.x), 0))


func exit():
	em.velocity = Vector2.ZERO
