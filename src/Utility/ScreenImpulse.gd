extends Node
class_name ScreenImpulse

var direction: Vector2   # normalized direction of the kick
var strength: float      # max pixel offset at peak
var duration: float      # total time out-and-back
var elapsed: float = 0.0
var curve: Curve         # shape of the impulse over time (0 to 1 -> 0 to 1)

func _init(dir: Vector2, st: float, dur: float, c: Curve):
	direction = dir.normalized()
	strength = st
	duration = dur
	curve = c
