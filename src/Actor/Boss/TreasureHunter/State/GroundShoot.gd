extends State

func state_start(_prev_state: StringName):
	if main.player_in_close_range:
		sm.change_state("melee")
		return
	main.face_player()
	main.ap.play("shoot")
	$FireTimer.start()
	$FinishTimer.start()

func state_end(_next_state: StringName):
	$FireTimer.stop()
	$FinishTimer.stop()

func state_physics_process(delta: float):
	main.keep_grounded(delta)

func _on_FireTimer_timeout():
	if main.player_in_close_range:
		sm.change_state("melee")
		return
	main.fire(Vector2(main.look_dir.x, 0.0))

func _on_FinishTimer_timeout():
	if main.player_in_close_range:
		sm.change_state("melee")
	else:
		sm.change_state("take_off")
