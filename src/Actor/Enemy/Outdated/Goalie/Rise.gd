extends State

@onready var em = get_parent().get_parent()
@onready var ap = em.get_node("AnimationPlayer")

func state_process():
	if em.is_on_ceiling():
		em.create_effect("Bonk")

	if em.is_on_ceiling() || em.position.y <= em.jump_pos.y || !em.target || em.position.y <= em.target.global_position.y:
		sm.change_state("fall")
		return
	em.velocity = calc_velocity()
	em.move_and_slide()
	em.velocity = em.velocity


func calc_velocity() -> Vector2:
	var out = em.velocity
	out.y = em.speed.y * em.move_dir.y
	return out

func enter():
	ap.play("Rise")
	am.play("enemy_jump", em)
	em.move_dir = Vector2.UP

func exit():
	em.velocity = Vector2.ZERO
