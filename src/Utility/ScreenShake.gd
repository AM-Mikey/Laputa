extends Node
class_name ScreenShake

var amplitude: float   # max offset in pixels
var duration: float    # seconds until falloff to zero
var elapsed: float = 0.0
var frequency: float   # effective "speed" of the shake's wobble
var seed_x: float
var seed_y: float

func _init(amp: float, dur: float, freq: float) -> void:
	amplitude = amp
	duration = dur
	frequency = freq
	# random offsets so simultaneous shakes don't sample identical noise
	seed_x = randf() * 1000.0
	seed_y = randf() * 1000.0
