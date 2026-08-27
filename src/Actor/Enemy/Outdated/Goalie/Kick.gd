extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if not ap.is_playing():
		sm.change_state("Fall")
		return



func enter():
	ap.play("Kick")
	if em.player_in_kick_zone and f.pc():
		f.pc().hit(em.kick_damage, Vector2(80 * em.look_dir.x, 0))


func exit():
	em.velocity = Vector2.ZERO
