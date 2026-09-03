extends Node
class_name ScreenShake

var amplitude: float
var base_amplitude: float
var duration: float
var elapsed: float = 0.0
var frequency: float
var seed_x: float
var seed_y: float

func _init(amp: float, base_amp: float, dur: float, freq: float):
	amplitude = amp
	base_amplitude = base_amp
	duration = dur
	frequency = freq
	# random offsets so simultaneous shakes don't sample identical noise
	seed_x = randf() * 1000.0
	seed_y = randf() * 1000.0
