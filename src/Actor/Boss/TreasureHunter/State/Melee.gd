extends State

func state_start(_prev_state: StringName):
	main.face_player()
	main.ap.play("gun_swing")
	main.get_node("SwingHitbox").position = Vector2(main.look_dir.x * 13.0, -16.0)
	main.get_node("SwingHitbox").set_deferred("monitoring", true)
	$Timer.start()

func state_end(_next_state: StringName):
	$Timer.stop()
	main.get_node("SwingHitbox").set_deferred("monitoring", false)

func state_physics_process(delta: float):
	main.keep_grounded(delta)

func _on_Timer_timeout():
	sm.change_state("ground_rush")
