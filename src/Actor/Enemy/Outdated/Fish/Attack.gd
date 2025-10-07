extends State

#var state_name = "Attack"

@onready var ap = get_parent().get_parent().get_node("AnimationPlayer")
@onready var em = get_parent().get_parent()


func state_process():
	if em.position.y <= em.jump_pos.y:
		sm.change_state("fall")
		return

	em.set_velocity(calc_velocity())
	em.move_and_slide()
	em.velocity = em.velocity


func calc_velocity() -> Vector2:
	var out = em.velocity
	
	out.y += em.gravity * get_physics_process_delta_time()
	if em.move_dir.y < 0:
		out.y = em.speed.y * em.move_dir.y
	
	return out

func enter():
	ap.play("Target")
	await ap.animation_finished
	em.move_dir = Vector2.UP

func exit():
	pass
