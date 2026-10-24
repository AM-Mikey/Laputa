extends State

var propeller_opened: = false

func state_start(_prev_state: StringName):
	main.velocity = Vector2.ZERO
	propeller_opened = false
	main.ap.play("propeller_open")

func state_physics_process(_delta: float):
	if propeller_opened:
		main.velocity = Vector2(0.0, -main.take_off_speed)
		main.move_and_slide()

		if main.global_position.y <= main.get_hover_height():
			main.global_position.y = main.get_hover_height()
			main.velocity = Vector2.ZERO
			sm.change_state("air")


func _on_AnimationPlayer_animation_finished(anim_name: StringName):
	if sm.state == "take_off":
		if anim_name == "propeller_open":
			propeller_opened = true
