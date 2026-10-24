extends State

func state_start(_prev_state: StringName):
	var air_state = main.get_node("StateMachine/Air")
	if not air_state.can_land():
		sm.change_state("air")
		return
	main.velocity = Vector2.ZERO
	main.ap.play("fly")

func state_physics_process(delta: float):
	main.velocity.x = 0.0
	main.velocity.y += main.gravity * delta
	main.move_and_slide()

	if main.is_on_floor():
		main.velocity = Vector2.ZERO
		main.ap.play("propeller_close")

func _on_AnimationPlayer_animation_finished(anim_name: StringName):
	if sm.state == "landing":
		if anim_name == "propeller_close":
			sm.change_state("ground")
