extends State

@export var delta_error: float = 4.0
var target_position: Vector2 = Vector2.ZERO
var reach_destination: bool = false
var move_speed: float = 60.0

var propeller_sound = null
var propeller_phase_2_spark_times: int = 0
var propeller_malfunction_timer := 0.0
var propeller_malfunction_elapsed := 0.0
var propeller_malfunctioning := false

const PROPELLER_MALFUNCTION_INTERVAL_MIN := 1.2
const PROPELLER_MALFUNCTION_INTERVAL_MAX := 1.8
const PROPELLER_MALFUNCTION_DURATION := 0.9
const PROPELLER_ALTITUDE_DROP := 24.0
const SMOKE_TIMER_MIN: = 0.1
const SMOKE_TIMER_MAX: = 0.3


func state_start(_prev_state: StringName):
	main.get_node("Hotspot/MoveToPhase2Pos").global_position = main.global_position
	reach_destination = false
	main.ap.play("fly")
	if main.phase_2_active:
		$Phase2SmokeTimer.start(randf_range(SMOKE_TIMER_MIN, SMOKE_TIMER_MAX))

func state_physics_process(delta: float):
	var distance_to_pos = main.global_position.distance_to(target_position)
	if distance_to_pos < delta_error:
		if !reach_destination:
			main.end_move_to.emit()
		reach_destination = true
		return

	if main.phase_2_active:
		var altitude_offset := 0.0
		if propeller_malfunctioning:
			propeller_malfunction_elapsed += delta
			var progress = clampf(propeller_malfunction_elapsed / PROPELLER_MALFUNCTION_DURATION, 0.0, 1.0)
			altitude_offset = PROPELLER_ALTITUDE_DROP * sin(progress * PI)
			if progress >= 1.0:
				propeller_malfunctioning = false
				propeller_malfunction_timer = randf_range(PROPELLER_MALFUNCTION_INTERVAL_MIN, PROPELLER_MALFUNCTION_INTERVAL_MAX)
		else:
			propeller_malfunction_timer -= delta
			if propeller_malfunction_timer <= 0.0:
				propeller_malfunctioning = true
				propeller_malfunction_elapsed = 0.0
				main.create_vfx("explosion", main.global_position + Vector2(0.0, -32.0))

		var direction = main.global_position.direction_to(target_position)
		main.get_node("Hotspot/MoveToPhase2Pos").global_position += direction * move_speed * delta
		var og_position: Vector2 = main.get_node("Hotspot/MoveToPhase2Pos").global_position
		main.global_position = Vector2(
			og_position.x,
			og_position.y + altitude_offset
		)
	else:
		var direction = main.global_position.direction_to(target_position)
		main.velocity = direction * move_speed
		main.move_and_slide()

func _on_Phase2SmokeTimer_timeout():
	var rand: = randi_range(1, 3)
	for i in range(0, rand):
		var offset = Vector2(randf_range(-18.0, 18.0), randf_range(-30.0, -4.0))
		var smoke_pos = main.global_position + offset
		main.create_vfx("smoke", smoke_pos)
	$Phase2SmokeTimer.start(randf_range(SMOKE_TIMER_MIN, SMOKE_TIMER_MAX))
