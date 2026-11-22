extends State

func state_start(_prev_state: StringName):
	main.ap.play("idle")
	if main.is_on_floor():
		$Timer.start()

func state_end(_next_state: StringName):
	$Timer.stop()

func state_physics_process(delta: float):
	main.keep_grounded(delta)
	if $Timer.time_left <= 0.0:
		if main.is_on_floor():
			$Timer.start()

func _on_Timer_timeout():
	if main.player_in_close_range:
		sm.change_state("melee")
	else:
		sm.change_state("ground_shoot")
