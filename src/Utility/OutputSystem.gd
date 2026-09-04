extends Node

var active_controller_color = Color.AQUAMARINE
var asleep_controller_color = Color.DARK_SLATE_BLUE
var inactive_controller_color = Color.BLACK

var level_gradient: Gradient
var fade_cycle_duration := 64.0

var time_elapsed := 0.0

func vibrate_impulse(strength: float, duration: float = 0.15):
	#if !Input.has_joy_vibration(device_index): return #TODO: 4.7 godot method
	if inp.controller_asleep: return
	_vibrate(strength * 0.3, strength * 0.9, duration)

func vibrate_impulse_light(strength: float, duration: float = 0.15):
	if inp.controller_asleep: return
	_vibrate(strength, 0, duration)

func vibrate_shake(weak_magnitude: float, strong_magnitude: float):
	#if !Input.has_joy_vibration(device_index): return
	if inp.controller_asleep: return
	_vibrate(weak_magnitude, strong_magnitude, get_process_delta_time() * 2.0)

func _vibrate(weak_magnitude: float, strong_magnitude: float, duration: float = 0.15):
	#if !Input.has_joy_vibration(inp.active_controller_index): return
	if inp.controller_asleep: return
	Input.start_joy_vibration(inp.active_controller_index, clamp(weak_magnitude, 0.0, 1.0), clamp(strong_magnitude, 0.0, 1.0), duration)

### lights ###

func _process(delta: float):
	time_elapsed += delta
	if level_gradient:
		var offset = fmod(time_elapsed, fade_cycle_duration) / fade_cycle_duration
		var color = level_gradient.sample(offset)
		set_controller_light_color(inp.active_controller_index, color)

func set_controller_light_color(index, color):
	if !Input.has_joy_light(index): return
	active_controller_color = color
	Input.set_joy_light(index, color)
