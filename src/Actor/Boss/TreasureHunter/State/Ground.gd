extends State

func state_start(_prev_state: StringName) -> void:
	main.ap.play("idle")
	$Timer.start()

func state_end(_next_state: StringName) -> void:
	$Timer.stop()

func state_physics_process(delta: float) -> void:
	main.keep_grounded(delta)

func _on_Timer_timeout() -> void:
	if main.player_in_close_range:
		sm.change_state("melee")
	else:
		sm.change_state("ground_shoot")
