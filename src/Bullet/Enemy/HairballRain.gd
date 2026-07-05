extends Bullet

@onready var ap = $AnimationPlayer
var fly_upward := true
var time_swing := 0.0
var swing_left_first := false

var max_swing_amplitude := 64.0
var min_swing_amplitude := 32.0
var curr_swing_amplitude := 0.0

var swing_gravity_mult := 0.08

func _init() -> void:
	gravity *= .5

func setup():
	is_wind_affected = true
	is_enemy_bullet = true
	ap.play("Rotate")
	velocity = speed * direction
	swing_left_first = randi() % 2 == 0
	curr_swing_amplitude = randf_range(min_swing_amplitude, max_swing_amplitude)

func _on_physics_process(_delta):
	velocity = calc_velocity(speed)
	move_and_slide()

func calc_velocity(projectile_speed) -> Vector2:
	fly_upward = velocity.y <= 0.0
	var out = velocity
	if fly_upward:
		out.x = projectile_speed * direction.x
		out.y += gravity * get_physics_process_delta_time()
		ap.speed_scale = out.length() / 300.0
	else:
		var phase := time_swing
		var phase_value = -cos(phase) if swing_left_first else cos(phase)
		if abs(phase_value) <= 0.01:
			curr_swing_amplitude = randf_range(min_swing_amplitude, max_swing_amplitude)
		out.x = curr_swing_amplitude * phase_value
		out.y = gravity * swing_gravity_mult * abs(phase_value)
		ap.speed_scale = abs(cos(phase)) * 2.0
		time_swing += get_physics_process_delta_time()
		time_swing = wrapf(time_swing, 0.0, 100.0)

	if wind_areas_inside.size() != 0: #Inside Wind
		if velocity.y < 0.0:
			velocity.y *= 0.9

	return out
