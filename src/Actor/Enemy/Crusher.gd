extends Enemy

const ICON = preload("res://assets/Actor/Enemy/CrusherIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Crusher.png")

# Time take to move from current postion -> to_pos. Not accounting for return trip
enum PathType {SEGMENT, RECTANGLE, ELLIPSE}
@export var path_type = PathType.RECTANGLE
@export var non_segment_path_reverse := false
@export var non_segment_path_start := 0.0
@export var travel_time: = 3.0
@export var loop := true
@export var crushing := true

var path: Curve2D = null
var path_length := 0.0

var start_pos: = Vector2.ZERO
var to_pos := Vector2.ZERO
var time :float = 0.0

var t_body = null
var t_dir = null

# Animating var
var prev_global_position := Vector2.ZERO
enum FacingDir {NEUTRAL, LEFT, RIGHT, UP, DOWN}
var facing_dir: FacingDir = FacingDir.NEUTRAL


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

	prev_global_position = global_position

	var new_path = Curve2D.new()
	match path_type:
		PathType.SEGMENT:
			to_pos = $ToPoint.global_position
			start_pos = global_position
			new_path.add_point(global_position)
			new_path.add_point($ToPoint.global_position)
			path_length = ($ToPoint.global_position - global_position).length()
			if loop:
				new_path.add_point(global_position)
				path_length *= 2.0
		PathType.RECTANGLE:
			var rect_global :Rect2 = $Shape.get_global_value()
			new_path.add_point(rect_global.position)
			new_path.add_point(rect_global.position + Vector2(rect_global.size.x, 0.0))
			new_path.add_point(rect_global.position + rect_global.size)
			new_path.add_point(rect_global.position + Vector2(0.0, rect_global.size.y))
			new_path.add_point(rect_global.position)
			path_length = (rect_global.size.x + rect_global.size.y) * 2.0
		PathType.ELLIPSE:
			var max_segment := 240.0
			var ellipse_a: float = $Shape.value.size.x / 2.0
			var ellipse_b: float = $Shape.value.size.y / 2.0
			var ellipse_center: Vector2 = $Shape.get_global_value().get_center()
			for i in range(0, max_segment):
				var curr_angle := float(i) * 2.0 * PI / max_segment
				var radius := ellipse_a * ellipse_b / sqrt(pow(ellipse_a * sin(curr_angle), 2) + pow(ellipse_b * cos(curr_angle), 2))
				var point_x := ellipse_center.x + radius * cos(curr_angle)
				var point_y := ellipse_center.y + radius * sin(curr_angle)
				new_path.add_point(Vector2(point_x, point_y))
			new_path.add_point(ellipse_center + Vector2(ellipse_a, 0))
			path = new_path
			path_length = path.get_baked_length()
	path = new_path

	if debug:
		debug_path_color = Color(randf(), randf(), randf(), 1.0)

	w.emit_signal("finished_spawn_entities_step")


func _physics_process(delta):
	if debug:
		queue_redraw()

	if disabled || dead:
		return

	time += delta
	if time >= travel_time:
		if loop:
			time = wrapf(time, 0.0, travel_time)
		else:
			time = travel_time
			prev_global_position = global_position
			animate()
			return

	var start_point = 0.0 if path_type == PathType.SEGMENT else non_segment_path_start
	# wrapf() is insufficent for this due to max_value is not inclusive,
	# causing Crusher to tp back to start on non-loop segment
	var t_value := 0.0
	if time <= travel_time:
		t_value = start_point + time / travel_time
		if t_value > 1.0:
			t_value = t_value - 1.0
		elif t_value < 0.0:
			t_value = 1.0 + t_value
	else:
		t_value = wrapf(start_point + time / travel_time, 0.0, 1.0)

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

@onready var ap = $AnimationPlayer
func animate():
	var move_angle = (global_position - prev_global_position).angle()
	if (global_position - prev_global_position).length() <= 0.01:
		facing_dir = FacingDir.NEUTRAL
	else:
		if abs(move_angle) >= 3.0 * PI / 4.0:
			facing_dir = FacingDir.LEFT
		elif abs(move_angle) < PI / 4.0:
			facing_dir = FacingDir.RIGHT
		elif move_angle <= -PI / 4.0 && move_angle > -3.0 * PI / 4.0:
			facing_dir = FacingDir.UP
		else:
			facing_dir = FacingDir.DOWN
