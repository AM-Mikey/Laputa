extends Node

var state_name = "Fall"

onready var ap = get_parent().get_parent().get_node("AnimationPlayer")
onready var em = get_parent().get_parent()

var has_recovered = false

func state_process():
	if not em.is_in_water:
		em.velocity = em.move_and_slide(get_velocity())
	elif not has_recovered:
		has_recovered = true
		$Tween.interpolate_property(em, "position", em.position, Vector2(em.position.x, em.start_pos.y), 0.8, Tween.TRANS_BACK, Tween.EASE_OUT)
		$Tween.start()
		yield($Tween, "tween_completed")
		em.change_state(em.states["idle"])

	
func get_velocity() -> Vector2:
	var out = em.velocity
	

	if not em.is_in_water:
		out.y += em.gravity * get_physics_process_delta_time()

	
	return out

func enter():
	ap.play("Fall")

func exit():
	has_recovered = false
