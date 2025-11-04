extends State

#var state_name = "Fall"

@onready var ap = get_parent().get_parent().get_node("AnimationPlayer")
@onready var em = get_parent().get_parent()

var has_recovered = false

func state_process():
	if not em.is_in_water:
		em.set_velocity(calc_velocity())
		em.move_and_slide()
		em.velocity = em.velocity
	elif not has_recovered:
		has_recovered = true
		var tween = get_tree().create_tween()
		tween.tween_property(em, "position", Vector2(em.position.x, em.start_pos.y), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		await tween.finished
		sm.change_state("idle")
		return


func calc_velocity() -> Vector2:
	var out = em.velocity


	if not em.is_in_water:
		out.y += em.gravity * get_physics_process_delta_time()


	return out

func enter():
	ap.play("Fall")

func exit():
	em.velocity = Vector2.ZERO
	has_recovered = false
