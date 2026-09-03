extends Node

var active_controller_color = Color.AQUAMARINE
var asleep_controller_color = Color.DARK_SLATE_BLUE
var inactive_controller_color = Color.BLACK

func vibrate_impulse(strength: float, duration: float = 0.15):
	#if !Input.has_joy_vibration(device_index): return #TODO: 4.7 godot method
	if inp.controller_asleep: return
	_vibrate(strength * 0.3, strength * 0.9, duration)

func vibrate_shake(weak_magnitude: float, strong_magnitude: float):
	#if !Input.has_joy_vibration(device_index): return
	if inp.controller_asleep: return
	_vibrate(weak_magnitude, strong_magnitude, get_process_delta_time() * 2.0)

func _vibrate(weak_magnitude: float, strong_magnitude: float, duration: float = 0.15):
	#if !Input.has_joy_vibration(inp.active_controller_index): return
	if inp.controller_asleep: return
	Input.start_joy_vibration(inp.active_controller_index, clamp(weak_magnitude, 0.0, 1.0), clamp(strong_magnitude, 0.0, 1.0), duration)


func set_controller_light_color(index, color):
	#if index = inp.active_controller_index:
		#active_controller_color = color
	Input.set_joy_light(index, color)

#func _input(event: InputEvent) -> void:
	#if event.is_action("debug_testbutton"):
		#var out = Input.get_connected_joypads()
		#for o in out:
			#print(Input.get_joy_info(o))
#
		#print(Input.get_connected_joypads())
