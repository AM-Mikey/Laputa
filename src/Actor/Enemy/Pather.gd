extends Enemy

const ICON = preload("res://assets/Actor/Enemy/CrusherIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Crusher.png")

enum PathType {RECTANGLE, ELLIPSE}
@export var path_type = PathType.RECTANGLE
@export var path_reverse := false
@export var path_start := 0.0
@export var travel_time: = 3.0
@export var loop := true
@export var crushing := true

var path: Curve2D = null

var time :float = 0.0
var path_length: float = 0.0

var t_body = null
var t_dir = null

var prev_global_position := Vector2.ZERO
var debug_path_color := Color.RED
var debug_path_start := true

func _draw():
	if debug and !dead:
		var draw_points: PackedVector2Array = path.get_baked_points()
		for i in range(draw_points.size()):
			draw_points[i] -= global_position
		draw_polyline(draw_points, debug_path_color, 2.0)

func setup():
	hp = 4
	reward = 2

	match path_type:
		PathType.RECTANGLE:
			var new_path = Curve2D.new()
			new_path.add_point($Shape.value.position)
			new_path.add_point($Shape.value.position + Vector2($Shape.value.size.x, 0.0))
			new_path.add_point($Shape.value.position + $Shape.value.size)
			new_path.add_point($Shape.value.position + Vector2(0.0, $Shape.value.size.y))
			new_path.add_point($Shape.value.position)
			path = new_path
			path_length = ($Shape.value.size.x + $Shape.value.size.y) * 2.0
		PathType.ELLIPSE:
			var max_segment := 240.0
			var new_path = Curve2D.new()
			var ellipse_a: float = $Shape.value.size.x / 2.0
			var ellipse_b: float = $Shape.value.size.y / 2.0
			var ellipse_center: Vector2 = $Shape.value.get_center()
			for i in range(0, max_segment):
				var curr_angle := float(i) * 2.0 * PI / max_segment
				var radius := ellipse_a * ellipse_b / sqrt(pow(ellipse_a * sin(curr_angle), 2) + pow(ellipse_b * cos(curr_angle), 2))
				var point_x := ellipse_center.x + radius * cos(curr_angle)
				var point_y := ellipse_center.y + radius * sin(curr_angle)
				new_path.add_point(Vector2(point_x, point_y))
			new_path.add_point(ellipse_center + Vector2(ellipse_a, 0))
			path = new_path
			path_length = path.get_baked_length()

	if debug:
		debug_path_color = Color(randf(), randf(), randf(), 1.0)
		if debug_path_start:
			path_start = randf()
	w.emit_signal("finished_spawn_entities_step")

func _physics_process(delta):
	if debug:
		queue_redraw()

	if disabled || dead:
		return

	if loop || time <= travel_time:
		time += delta
	else:
		time = travel_time
		return

	var t_value := wrapf(path_start + time / travel_time, 0.0, 1.0)

	global_position = path.sample_baked(t_value * path_length)

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
