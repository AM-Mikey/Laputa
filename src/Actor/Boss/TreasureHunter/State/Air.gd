extends State

enum FlightMode { HOVERING, MOVING_TO_SWEEP_START, SWEEPING }

@export var hover_duration := 10.0
@export var hover_horizontal_speed := 150.0
@export var hover_vertical_amplitude := 12.0
@export var flare_interval_min := 0.8
@export var flare_interval_max := 1.4
@export var sweep_horizontal_speed := 150.0
@export var sweep_shot_interval := 0.5

var arena_rect := Rect2()
var arena_center_x := 0.0
var horizontal_radius := 0.0
var left_end_x := 0.0
var right_end_x := 0.0
var phase := 0.0
var phase_speed := 0.0
var hover_height := 0.0
var flight_mode: FlightMode = FlightMode.HOVERING
var sweep_target_x := 0.0
var sweep_attack_finished := false

var propeller_sound = null

func state_start(_prev_state: StringName):
	arena_rect = main.get_arena_rect()
	arena_center_x = arena_rect.get_center().x
	left_end_x = arena_rect.position.x + 24.0
	right_end_x = arena_rect.end.x - 24.0
	horizontal_radius = (right_end_x - left_end_x) * 0.5
	phase = asin(clampf((main.global_position.x - arena_center_x) / horizontal_radius, -1.0, 1.0))
	phase_speed = hover_horizontal_speed / horizontal_radius
	hover_height = main.get_hover_height()
	flight_mode = FlightMode.HOVERING
	sweep_attack_finished = false
	main.ap.play("fly")
	propeller_sound = am.play("boss_treasure_hunter_flare_propeller_loop", main, null, 0.8, 0.0)
	$DurationTimer.start(hover_duration)
	start_flare_timer()

func state_end(_next_state: StringName):
	$DurationTimer.stop()
	$FlareTimer.stop()
	$ReloadTimer.stop()
	$SweepFireTimer.stop()
	if propeller_sound:
		am.stop_sfx()

func state_physics_process(delta: float):
	match flight_mode:
		FlightMode.HOVERING:
			phase += phase_speed * delta
			main.global_position = Vector2(
				arena_center_x + horizontal_radius * sin(phase),
				hover_height + hover_vertical_amplitude * sin(phase * 2.0)
			)
			main.look_dir = Vector2(sign(cos(phase)), 0.0)
			if $DurationTimer.time_left <= 1.0:
				if $FlareTimer.time_left > 0.0:
					$FlareTimer.stop()
				if $ReloadTimer.time_left > 0.0:
					$ReloadTimer.stop()
				var nearest_end = left_end_x if abs(main.global_position.x - left_end_x) < abs(main.global_position.x - right_end_x) else right_end_x
				if main.is_at_x(nearest_end):
					flight_mode = FlightMode.MOVING_TO_SWEEP_START
					sweep_target_x = nearest_end
					main.look_dir = Vector2(sign(sweep_target_x - main.global_position.x), 0.0)
		FlightMode.MOVING_TO_SWEEP_START:
			move_straight_toward(sweep_target_x, delta)
			if main.is_at_x(sweep_target_x):
				main.global_position.x = sweep_target_x
				start_sweep()
		FlightMode.SWEEPING:
			move_straight_toward(sweep_target_x, delta)
			if main.is_at_x(sweep_target_x):
				main.global_position.x = sweep_target_x
				sweep_attack_finished = true
				if can_land():
					sm.change_state("landing")

### UTILITY ###
func start_flare_timer():
	$FlareTimer.start(randf_range(flare_interval_min, flare_interval_max))

func start_sweep():
	flight_mode = FlightMode.SWEEPING
	sweep_target_x = right_end_x if main.global_position.x <= arena_center_x else left_end_x
	main.look_dir = Vector2(sign(sweep_target_x - main.global_position.x), 0.0)
	main.ap.play("fly")
	main.fire(Vector2.DOWN)
	$SweepFireTimer.start(sweep_shot_interval)

func move_straight_toward(target_x: float, delta: float):
	var direction = sign(target_x - main.global_position.x)
	main.look_dir = Vector2(direction, 0.0)
	main.global_position.x = move_toward(main.global_position.x, target_x, sweep_horizontal_speed * delta)
	main.global_position.y = hover_height

func can_land() -> bool:
	return sweep_attack_finished and (
		main.is_at_x(left_end_x) or main.is_at_x(right_end_x)
	)



### SIGNALS ###
func _on_DurationTimer_timeout():
	$FlareTimer.stop()
	$ReloadTimer.stop()
	#main.ap.play("fly")
	#var nearest_end = left_end_x if abs(main.global_position.x - left_end_x) < abs(main.global_position.x - right_end_x) else right_end_x
	#flight_mode = FlightMode.MOVING_TO_SWEEP_START
	#sweep_target_x = nearest_end
	#main.look_dir = Vector2(sign(sweep_target_x - main.global_position.x), 0.0)

func _on_FlareTimer_timeout():
	if flight_mode != FlightMode.HOVERING:
		return
	var flare_direction = Vector2.DOWN
	if randi() % 2 == 1 and main.pc != null:
		flare_direction = Vector2(
			sign(main.pc.global_position.x - main.global_position.x),
			1.0
		).normalized()
	main.fire(flare_direction)
	main.ap.play("fly_shoot_down")
	$ReloadTimer.start()
	start_flare_timer()

func _on_SweepFireTimer_timeout():
	if flight_mode != FlightMode.SWEEPING:
		return
	main.fire(Vector2.DOWN)
	main.ap.play("fly_shoot_down")
	$ReloadTimer.start()
	$SweepFireTimer.start(sweep_shot_interval)

func _on_ReloadTimer_timeout():
	if flight_mode != FlightMode.HOVERING or !$FlareTimer.is_stopped():
		main.ap.play("fly")
