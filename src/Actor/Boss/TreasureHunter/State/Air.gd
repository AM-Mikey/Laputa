extends State

enum FlightMode { HOVERING, MOVING_TO_SWEEP_START, SWEEPING }

@export var hover_duration := 7.0
@export var hover_horizontal_speed := 85.0
@export var hover_vertical_amplitude := 10.0
@export var flare_interval_min := 1.5
@export var flare_interval_max := 1.5
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
var prev_global_position: = Vector2.ZERO

var propeller_sfx = null
var propeller_rev_sfx = null
var propeller_phase_2_spark_times: int = 0
var propeller_malfunction_timer := 0.0
var propeller_malfunction_elapsed := 0.0
var propeller_malfunctioning := false

var phase_2_bullet_hell: = false:
	set(val):
		if main.phase_2_active:
			if !phase_2_bullet_hell and val: # Start bullet hell attack
				#$Phase2SparkTimer.stop()
				$FlareTimer.stop()
				phase_2_bullet_hell_bullet_no = 0
				for i in range(0, 3):
					am.play("boss_treasure_hunter_flare_propeller_electric", main, null, 4.0, 1.0)
					main.create_vfx("malfunction_spark", main.global_position + Vector2(randf_range(-5.0, 5.0), randf_range(-30.0, 0.0)))
					await get_tree().create_timer(randf_range(0.05, 0.1)).timeout
				await get_tree().create_timer(0.2).timeout
				main.create_vfx("explosion", main.global_position + Vector2(0.0, -32.0))
				await get_tree().create_timer(0.2).timeout
				main.create_vfx("explosion", main.global_position + Vector2(0.0, -32.0))
				await get_tree().create_timer(0.1).timeout
				main.create_vfx("explosion", main.global_position + Vector2(0.0, -32.0))
				await get_tree().create_timer(0.2).timeout
				propeller_malfunction()
				await get_tree().create_timer(0.3).timeout
				main.ap.play("fly_fast_spin_start")
				main.ap.queue("fly_fast_spin")
				$Phase2BulletHellDuration.start()
				#$Phase2BulletHellBulletSpawn.start()
			elif phase_2_bullet_hell and !val: # End bullet hell attack
				#$Phase2SparkTimer.stop()
				start_phase_2_bullet_hell_cooldown_timer()
				start_flare_timer()
				propeller_rev_sfx.stop()
				$Phase2BulletHellDuration.stop()
				$Phase2BulletHellBulletSpawn.stop()
				propeller_phase_2_spark_times = 0
				main.ap.play("fly_fast_spin_end")
				main.ap.queue("fly")
		phase_2_bullet_hell = val

const PHASE_2_SPARK_INTERVAL_MIN := 1.8
const PHASE_2_SPARK_INTERVAL_MAX := 1.8
const PHASE_2_FLARE_TIMER:= 1.5
const PHASE_2_HORIZONTAL_SPEED = 100.0
const PROPELLER_MALFUNCTION_INTERVAL_MIN := 1.8
const PROPELLER_MALFUNCTION_INTERVAL_MAX := 1.8
const PROPELLER_MALFUNCTION_DURATION := 1.5
const PROPELLER_ALTITUDE_DROP := 40.0
const SMOKE_TIMER_MIN: = 0.1
const SMOKE_TIMER_MAX: = 0.3
const SPARK_FORCE_MIN: = 40.0
const SPARK_FORCE_MAX: = 120.0

const PHASE_2_BULLET_HELL_COOLDOWN_MIN := 10.0
const PHASE_2_BULLET_HELL_COOLDOWN_MAX := 10.0

func state_start(_prev_state: StringName):
	if !propeller_sfx:
		propeller_sfx = main.get_node("PropellerLoop")
	if !propeller_rev_sfx:
		propeller_rev_sfx = main.get_node("PropellerRevLoop")
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
	propeller_sfx.play()
	if main.phase_2_active:
		phase_speed = PHASE_2_HORIZONTAL_SPEED / horizontal_radius
		propeller_phase_2_spark_times = 0
		propeller_malfunction_timer = randf_range(PROPELLER_MALFUNCTION_INTERVAL_MIN, PROPELLER_MALFUNCTION_INTERVAL_MAX)

		propeller_malfunctioning = true
		propeller_malfunction_elapsed = 0.0
		main.create_vfx("explosion", main.global_position + Vector2(0.0, -32.0))

		phase_2_bullet_hell = false
		start_phase_2_bullet_hell_cooldown_timer()

		$Phase2SmokeTimer.start(randf_range(SMOKE_TIMER_MIN, SMOKE_TIMER_MAX))
		#$Phase2SparkTimer.start(randf_range(PHASE_2_SPARK_INTERVAL_MIN, PHASE_2_SPARK_INTERVAL_MAX))
		start_flare_timer()
		return
	$DurationTimer.start(hover_duration)
	start_flare_timer()

func state_end(_next_state: StringName):
	$DurationTimer.stop()
	$FlareTimer.stop()
	$ReloadTimer.stop()
	$SweepFireTimer.stop()
	$Phase2SmokeTimer.stop()
	$Phase2BulletHellCooldown.stop()
	$Phase2BulletHellDuration.stop()
	$Phase2BulletHellBulletSpawn.stop()
	propeller_sfx.stop()
	#$Phase2SparkTimer.stop()
	propeller_phase_2_spark_times = 0


func state_physics_process(delta: float):
	if main.phase_2_active:
		process_phase_2(delta)
		return

	match flight_mode:
		FlightMode.HOVERING:
			phase += phase_speed * delta
			prev_global_position = main.global_position
			main.global_position = Vector2(
				arena_center_x + horizontal_radius * sin(phase),
				hover_height + hover_vertical_amplitude * sin(phase * 2.0)
			)
			if main.pc:
				main.look_dir = Vector2(sign(main.pc.global_position.x - main.global_position.x), 0.0)
			else:
				main.look_dir = Vector2(sign(cos(phase)), 0.0)
			if $DurationTimer.time_left <= 0.0:
				var nearest_end = left_end_x if abs(main.global_position.x - left_end_x) < abs(main.global_position.x - right_end_x) else right_end_x
				if main.is_near_x(nearest_end) && (main.global_position.x - prev_global_position.x) * (nearest_end - main.global_position.x) > 0:
					if $FlareTimer.time_left > 0.0:
						$FlareTimer.stop()
					if $ReloadTimer.time_left > 0.0:
						$ReloadTimer.stop()
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

func process_phase_2(delta: float):
	phase += phase_speed * delta
	var altitude = hover_height + hover_vertical_amplitude * sin(phase * 2.0)
	main.look_dir = Vector2(sign(cos(phase)), 0.0)

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

			if !phase_2_bullet_hell:
				var xp_spawn_values = []
				var xp_spawn = randi() % 3
				for i in range(0, xp_spawn, 1):
					xp_spawn_values.append(1)
				main.spawn_xp(xp_spawn_values)

				if propeller_phase_2_spark_times % 4 == 3:
					for index in range(8):
						main.fire_spark(Vector2.RIGHT.rotated(TAU * index / 8.0) * SPARK_FORCE_MAX)
						#$Phase2SparkTimer.start(randf_range(PHASE_2_SPARK_INTERVAL_MIN, PHASE_2_SPARK_INTERVAL_MAX) * 2.0)
				else:
					for index in range(0, randi() % 3 + 1):
						main.fire_spark(Vector2.RIGHT.rotated(randf_range(-PI, 0.0)) * randf_range(SPARK_FORCE_MIN, SPARK_FORCE_MAX))
					#$Phase2SparkTimer.start(randf_range(PHASE_2_SPARK_INTERVAL_MIN, PHASE_2_SPARK_INTERVAL_MAX))
				propeller_phase_2_spark_times += 1
			main.create_vfx("explosion", main.global_position + Vector2(0.0, -32.0))

	prev_global_position = main.global_position
	main.global_position = Vector2(
		arena_center_x + horizontal_radius * sin(phase),
		altitude + altitude_offset
	)

### UTILITY ###
func start_flare_timer():
	if !main.phase_2_active:
		$FlareTimer.start(randf_range(flare_interval_min, flare_interval_max))
	else:
		$FlareTimer.start(PHASE_2_FLARE_TIMER)

func start_phase_2_bullet_hell_cooldown_timer():
	$Phase2BulletHellCooldown.start(randf_range(PHASE_2_BULLET_HELL_COOLDOWN_MIN, PHASE_2_BULLET_HELL_COOLDOWN_MAX))

func propeller_malfunction():
	propeller_malfunctioning = true
	propeller_malfunction_elapsed = 0.0

func move_straight_toward(target_x: float, delta: float):
	var direction = sign(target_x - main.global_position.x)
	main.look_dir = Vector2(direction, 0.0)
	main.global_position.x = move_toward(main.global_position.x, target_x, sweep_horizontal_speed * delta)
	main.global_position.y = hover_height

func can_land() -> bool:
	return sweep_attack_finished and (
		main.is_at_x(left_end_x) or main.is_at_x(right_end_x)
	)

func start_sweep():
	flight_mode = FlightMode.SWEEPING
	sweep_target_x = right_end_x if main.global_position.x <= arena_center_x else left_end_x
	main.look_dir = Vector2(sign(sweep_target_x - main.global_position.x), 0.0)
	main.ap.play("fly")
	main.fire(Vector2.DOWN)
	$SweepFireTimer.start(sweep_shot_interval)

### SIGNALS ###
func _on_FlareTimer_timeout():
	if flight_mode not in [FlightMode.HOVERING, FlightMode.MOVING_TO_SWEEP_START]:
		return
	var flare_direction = Vector2.DOWN
	if !main.phase_2_active:
		flare_direction = Vector2(
			sign(main.pc.global_position.x - main.global_position.x),
			1.0
		).normalized()
	#if randi() % 2 == 1 and main.pc != null:
		#flare_direction = Vector2(
			#sign(main.pc.global_position.x - main.global_position.x),
			#1.0
		#).normalized()
	main.fire(flare_direction)
	main.ap.play("fly_shoot_down")
	#$ReloadTimer.start()
	start_flare_timer()
	await get_tree().create_timer(0.5).timeout
	main.reload()


func _on_SweepFireTimer_timeout():
	if flight_mode != FlightMode.SWEEPING:
		return
	main.fire(Vector2.DOWN)
	main.ap.play("fly_shoot_down") #WIP: Replace with reload animatio
	#$ReloadTimer.start()
	$SweepFireTimer.start(sweep_shot_interval)
	await get_tree().create_timer(0.5).timeout
	main.reload()

func _on_ReloadTimer_timeout():
	if flight_mode != FlightMode.HOVERING or !$FlareTimer.is_stopped():
		main.ap.play("fly")

func _on_DurationTimer_timeout():
	pass
	#$FlareTimer.stop()
	#$ReloadTimer.stop()
	#main.ap.play("fly")
	#var nearest_end = left_end_x if abs(main.global_position.x - left_end_x) < abs(main.global_position.x - right_end_x) else right_end_x
	#flight_mode = FlightMode.MOVING_TO_SWEEP_START
	#sweep_target_x = nearest_end
	#main.look_dir = Vector2(sign(sweep_target_x - main.global_position.x), 0.0)

func _on_Phase2SmokeTimer_timeout():
	var rand: = randi_range(1, 3)
	for i in range(0, rand):
		var offset = Vector2(randf_range(-15.0, 15.0), randf_range(-30.0, -4.0))
		var smoke_pos = main.global_position + offset
		main.create_vfx("smoke", smoke_pos)
	$Phase2SmokeTimer.start(randf_range(SMOKE_TIMER_MIN, SMOKE_TIMER_MAX))


func _on_Phase2SparkTimer_timeout():
	return
	#if propeller_phase_2_spark_times % 4 == 3:
		#for index in range(8):
			#main.fire_spark(Vector2.RIGHT.rotated(TAU * index / 8.0) * SPARK_FORCE_MAX)
			#$Phase2SparkTimer.start(randf_range(PHASE_2_SPARK_INTERVAL_MIN, PHASE_2_SPARK_INTERVAL_MAX) * 2.0)
	#else:
		#for index in range(0, randi() % 3 + 1):
			#main.fire_spark(Vector2.RIGHT.rotated(randf_range(-PI, 0.0)) * randf_range(SPARK_FORCE_MIN, SPARK_FORCE_MAX))
		#$Phase2SparkTimer.start(randf_range(PHASE_2_SPARK_INTERVAL_MIN, PHASE_2_SPARK_INTERVAL_MAX))
	#propeller_phase_2_spark_times += 1


func _on_Phase2BulletHellCooldown_timeout() -> void:
	phase_2_bullet_hell = true

func _on_Phase2BulletHellDuration_timeout() -> void:
	if main.phase_2_active:
		phase_2_bullet_hell = false

var phase_2_bullet_hell_bullet_no: = 0
func _on_Phase2BulletHellBulletSpawn_timeout() -> void:
	main.fire_spark(Vector2(sin(TAU * phase_2_bullet_hell_bullet_no / 8.0 + PI / 8.0) * SPARK_FORCE_MAX, -50.0))
	phase_2_bullet_hell_bullet_no += 1
	$Phase2BulletHellBulletSpawn.start()

func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	if main.sm.state == "air":
		match anim_name:
			"fly_fast_spin_start":
				if phase_2_bullet_hell:
					$Phase2BulletHellBulletSpawn.start()
					propeller_rev_sfx.play()
				else:
					start_flare_timer()
			"reload":
				if !phase_2_bullet_hell:
					main.ap.play("fly")
