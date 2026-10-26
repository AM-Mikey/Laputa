extends State

const TRANSITION_DURATION := 1.2

var elapsed := 0.0
var next_explosion_time := 0.0
var was_grounded := false

func state_start(_prev_state: StringName):
	was_grounded = main.is_on_floor()
	elapsed = 0.0
	next_explosion_time = 0.0
	main.velocity = Vector2.ZERO
	main.ap.play("fly")

func state_physics_process(_delta: float):
	main.velocity = Vector2.ZERO

func state_process(delta: float):
	elapsed += delta
	if elapsed >= TRANSITION_DURATION:
		sm.change_state("take_off" if was_grounded else "air")
		return

	if elapsed >= next_explosion_time:
		var offset = Vector2(randf_range(-18.0, 18.0), randf_range(-30.0, -4.0))
		main.create_vfx("explosion", main.global_position + offset)
		next_explosion_time = elapsed + randf_range(0.07, 0.16)
