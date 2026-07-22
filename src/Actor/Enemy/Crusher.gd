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

var nearby_bodies: Array = []
var t_body = null
var t_dir = null

# Animating var
var prev_global_position := Vector2.ZERO
enum FacingDir {NEUTRAL, LEFT, RIGHT, UP, DOWN}
var facing_dir: FacingDir = FacingDir.NEUTRAL


var debug_path_color := Color.RED
var debug_path_start := true
var debug_name = ["Crusher42"]
#["Crusher60", "Crusher58", "Crusher42", "Crusher43", "Crusher44", "Crusher45", "Crusher46", "Crusher47", "Crusher48", "Crusher49"]

var bod_rect : Rect2
var self_rect : Rect2
var over_rect : Rect2

func _draw():
	if name in debug_name:
		var draw_bod_rect = Rect2(bod_rect.position - global_position, bod_rect.size)
		var draw_self_rect = Rect2(self_rect.position - global_position, self_rect.size)
		var draw_over_rect = Rect2(over_rect.position - global_position, over_rect.size)
		draw_rect(draw_bod_rect, Color.BLUE)
		draw_rect(draw_self_rect, Color.RED)
		draw_rect(draw_over_rect, Color.PURPLE)
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
			var ellipse_a: float = $Shape.value.size.x / 2.0
			var ellipse_b: float = $Shape.value.size.y / 2.0
			var max_segment: float = max(TAU * (ellipse_a + ellipse_b) / 2.0 / 10.0, 40.0)
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

	if crushing:
		crush_check()

	animate()
	prev_global_position = global_position


func on_crush_body_entered(body):
	if !nearby_bodies.has(body):
		nearby_bodies.append(body)

func on_crush_body_exited(body):
	if nearby_bodies.has(body):
		nearby_bodies.erase(body)



func crush_check():
	var crush_rect_size = $Crush/CollisionShape2D.shape.size
	var crush_rect := Rect2($Crush/CollisionShape2D.global_position - crush_rect_size / 2.0, crush_rect_size)
	var crush_rect_center := crush_rect.get_center()

	var tolerance = min(path_length / travel_time / 333.33, 1.0)
	var moving_direction := global_position - prev_global_position
	moving_direction.x = sign(moving_direction.x) if abs(moving_direction.x) > tolerance else 0.0
	moving_direction.y = sign(moving_direction.y) if abs(moving_direction.y) > tolerance else 0.0

	if moving_direction == Vector2.ZERO: return

	#if name in debug_name:
		#print(name, " ", nearby_bodies.size())
	for body in nearby_bodies:
		if body.get_collision_layer_value(1):
			body = body.get_parent()

		var body_collision_shape = body.get_node("CollisionShape2D")
		if !body_collision_shape or body_collision_shape.disabled:
			continue

		var body_size = body_collision_shape.shape.get_rect().size
		var body_rect := Rect2(body_collision_shape.global_position - body_size / 2.0, body_size)
		var body_overlap_rect := body_rect.intersection(crush_rect)

		#if name in debug_name:
			#self_rect = crush_rect
			#bod_rect = body_rect
			#over_rect = body_overlap_rect
			#queue_redraw()
		if body_overlap_rect != Rect2():
			var body_position = body_overlap_rect.get_center()
			var raycheck_position := Vector2.ZERO
			var check_direction := Vector2.ZERO

			#if name in debug_name:
				#print("Find raycheck")

			if moving_direction.x < 0.0 and body_position.x < crush_rect_center.x:
				check_direction.x = -1
				raycheck_position = body_rect.position + Vector2(0.0, body_rect.size.y / 2.0)
			elif moving_direction.x > 0.0 and body_position.x > crush_rect_center.x:
				check_direction.x = 1
				raycheck_position = body_rect.position + Vector2(body_rect.size.x, body_rect.size.y / 2.0)
			if moving_direction.y < 0.0 and body_position.y < crush_rect_center.y:
				check_direction.y = -1
				raycheck_position = body_rect.position + Vector2(body_rect.size.x / 2.0, 0.0)
			elif moving_direction.y > 0.0 and body_position.y > crush_rect_center.y:
				check_direction.y = 1
				raycheck_position = body_rect.position + Vector2(body_rect.size.x / 2.0, body_rect.size.y)

			if check_direction == Vector2.ZERO: continue

			#if name in debug_name:
				#print(check_direction)

			var raycheck_param: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
			#raycheck_param.transform = Transform2D(body_collision_shape.global_rotation, body_collision_shape.global_scale, 0.0, body_collision_shape.global_position)
			#raycheck_param.motion = check_direction
			#raycheck_param.shape = body_collision_shape.shape
			raycheck_param.from = raycheck_position
			raycheck_param.to = raycheck_position + check_direction
			raycheck_param.exclude = [body.get_rid()]
			raycheck_param.collision_mask = 8
			raycheck_param.hit_from_inside = true
			raycheck_param.collide_with_bodies = true
			raycheck_param.collide_with_areas = false

			var collide_with_world: bool = false
			var physics_space = get_world_2d().direct_space_state
			var collision = physics_space.intersect_ray(raycheck_param)
			while !collision.is_empty():
				var collider = collision["collider"]
				if collider.is_in_group("CrusherStandable"):
					var exception = raycheck_param.exclude
					exception.append(collider.get_rid())
					raycheck_param.exclude = exception
					collision = physics_space.intersect_ray(raycheck_param)
				else:
					#if name in debug_name:
						#print("A")
						#print(check_direction, " ", collider.name)
					collide_with_world = true
					break

			if collide_with_world:
				body.hit(999, Vector2.ZERO)
				body.die() # Pierce invis

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
