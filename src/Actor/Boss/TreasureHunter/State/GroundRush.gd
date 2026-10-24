extends State

var target_x := 0.0

func state_start(_prev_state: StringName):
	target_x = main.get_opposite_arena_side()
	var direction = sign(target_x - main.global_position.x)
	main.look_dir = Vector2(direction, 0.0)
	main.ap.play("run_forward")

func state_physics_process(delta: float):
	var direction = sign(target_x - main.global_position.x)
	if direction == 0.0:
		sm.change_state("take_off")
		return

	main.velocity.x = direction * main.ground_rush_speed
	if main.is_on_floor():
		main.velocity.y = 0.0
	else:
		main.velocity.y += main.gravity * delta
	main.move_and_slide()

	if direction * (target_x - main.global_position.x) <= 0.0:
		main.global_position.x = target_x
		main.velocity.x = 0.0
		sm.change_state("take_off")
