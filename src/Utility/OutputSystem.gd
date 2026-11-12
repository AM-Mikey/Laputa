extends Node

var active_controller_color = Color.AQUAMARINE
var asleep_controller_color = Color.DARK_SLATE_GRAY
var inactive_controller_color = Color.BLACK

var level_gradient: Gradient
var do_level_gradient := true
var fade_cycle_duration := 64.0
var _fade_tween: Tween
var _fading := false

var real_delta := 0.0
var time_elapsed := 0.0
var _last_ticks_usec := 0

func _ready():
	_last_ticks_usec = Time.get_ticks_usec()

func vibrate_impulse(strength: float, duration: float = 0.15):
	#if !Input.has_joy_vibration(device_index): return #TODO: 4.7 godot method
	var weak_mult = lerp(0.3, 1.0, strength)
	var strong_mult = lerp(0.9, 1.0, strength)
	_vibrate(strength * weak_mult, strength * strong_mult, duration)

func vibrate_impulse_light(strength: float, duration: float = 0.15):
	if inp.controller_asleep: return
	_vibrate(strength, 0, duration)

func vibrate_shake(weak_magnitude: float, strong_magnitude: float):
	#if !Input.has_joy_vibration(device_index): return
	if inp.controller_asleep: return
	_vibrate(weak_magnitude, strong_magnitude, maxf(real_delta * 2.0, 0.05))


### lights ###

func _process(_delta: float):
	var now := Time.get_ticks_usec()
	real_delta = (now - _last_ticks_usec) / 1_000_000.0
	_last_ticks_usec = now

	time_elapsed += real_delta
	if do_level_gradient && level_gradient:
		var offset = fmod(time_elapsed, fade_cycle_duration) / fade_cycle_duration
		var color = level_gradient.sample(offset)
		set_controller_light_color(inp.active_controller_index, color)

func set_controller_light_color(index, color):
	if !Input.has_joy_light(index): return
	active_controller_color = color
	Input.set_joy_light(index, color)

func fade_to_gradient(new_gradient: Gradient, duration: float = 1.0):
	if !new_gradient: return
	var tween = _fade_light_to(new_gradient.sample(0.0), duration)
	tween.finished.connect(_start_gradient.bind(new_gradient))

#func fade_to_black(duration: float = 1.0, next_gradient: Gradient = null):
	#var tween = _fade_light_to(Color.BLACK, duration)
	#tween.finished.connect(_start_gradient.bind(next_gradient))



### HELPER

func _vibrate(weak_magnitude: float, strong_magnitude: float, duration: float = 0.15):
	#if !Input.has_joy_vibration(inp.active_controller_index): return
	if inp.controller_asleep: return
	Input.start_joy_vibration(inp.active_controller_index, clamp(weak_magnitude, 0.0, 1.0), clamp(strong_magnitude, 0.0, 1.0), duration)

func _fade_light_to(target: Color, duration: float) -> Tween:
	if _fade_tween: _fade_tween.kill()
	_fading = true
	_fade_tween = create_tween()
	_fade_tween.set_ignore_time_scale(true)
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_method(
		func(c: Color): set_controller_light_color(inp.active_controller_index, c),
		active_controller_color, target, duration)
	return _fade_tween

func _start_gradient(new_gradient: Gradient):
	level_gradient = new_gradient
	time_elapsed = 0.0
	_fading = false
