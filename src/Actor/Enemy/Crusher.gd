extends Enemy

const ICON = preload("res://assets/Actor/Enemy/CrusherIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Crusher.png")

# Time take to move from current postion -> to_pos. Not accounting for return trip
@export var travel_time: = 3.0
@export var loop := true
@export var crushing := true

var start_pos: = Vector2.ZERO
var to_pos := Vector2.ZERO
var time :float = 0.0

var t_body = null
var t_dir = null

var prev_global_position := Vector2.ZERO

func setup():
	hp = 4
	reward = 2

	to_pos = $ToPoint.global_position
	start_pos = global_position
	prev_global_position = global_position
	w.emit_signal("finished_spawn_entities_step")


func _physics_process(delta):
	if disabled || dead:
		return

	if loop || time <= travel_time:
		time += delta
	else:
		time = travel_time
		return

	var t_value := wrapf(time / travel_time, 0.0, 2.0)
	if t_value <= 1.0:
		t_value  = t_value
	else:
		t_value = 1.0 - (t_value - 1.0)

	global_position = lerp(start_pos, to_pos, t_value)

	if t_body != null and crushing:
		crush_check()

	animate()
	prev_global_position = global_position


func on_crush_body_entered(body, dir):
	t_body = body.get_parent()
	t_dir = dir

func on_crush_body_exited(_body):
	t_body = null
	t_dir = null

func crush_check():
	match t_dir:
		"up":
			if t_body.is_on_ceiling():
				t_body.hit(999, Vector2.ZERO)
		"down":
			if t_body.is_on_floor():
				t_body.hit(999, Vector2.ZERO)


func animate():
	var move_angle = (global_position - prev_global_position).angle()
	if (global_position - prev_global_position).length() <= 0.01:
		$Sprite2D.frame = 0
	else:
		if abs(move_angle) >= 3.0 * PI / 4.0 :
			$Sprite2D.frame = 1
		elif abs(move_angle) < PI / 4.0:
			$Sprite2D.frame = 2
		elif move_angle <= -PI / 4.0 && move_angle > -3.0 * PI / 4.0:
			$Sprite2D.frame = 3
		else:
			$Sprite2D.frame = 4
