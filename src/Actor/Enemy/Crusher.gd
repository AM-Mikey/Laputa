extends Enemy

const ICON = preload("res://assets/Actor/Enemy/CrusherIcon.png")
const TX_0 = preload("res://assets/Actor/Enemy/Crusher.png")


enum PathType {SEGMENT, RECTANGLE, ELLIPSE}
@export var path_type = PathType.RECTANGLE
@export var non_segment_path_reverse := false
@export var non_segment_path_start := 0.0
@export var travel_time: = 3.0 # Time to travel the whole path. If path_type = segment && loop = false, travel time does not account for the return trip.
@export var loop := true
@export var crushing := true

var path: Curve2D = null
var path_length := 0.0

var start_pos: = Vector2.ZERO
var to_pos := Vector2.ZERO
var time := 0.0

var nearby_bodies := []
var t_body = null
var t_dir = null

# Animating var
var moving_direction := Vector2.ZERO
var prev_global_position := Vector2.ZERO
enum FacingDir {NEUTRAL, LEFT, RIGHT, UP, DOWN}
var facing_dir: FacingDir = FacingDir.NEUTRAL

# Debug
var debug_path_color := Color.RED
var debug_self_rect := Rect2()
var debug_body_rect := Rect2()
var debug_over_rect := Rect2()

func _draw():
	if debug:
		var draw_points := path.get_baked_points()
		for i in range(draw_points.size()):
			draw_points[i] -= global_position
		draw_polyline(draw_points, debug_path_color, 2.0)

		var draw_bod_rect = Rect2(debug_body_rect.position - global_position, debug_body_rect.size)
		var draw_self_rect = Rect2(debug_self_rect.position - global_position, debug_self_rect.size)
		var draw_over_rect = Rect2(debug_over_rect.position - global_position, debug_over_rect.size)
		draw_rect(draw_bod_rect, Color.BLUE)
		draw_rect(draw_self_rect, Color.RED)
		draw_rect(draw_over_rect, Color.PURPLE)

func setup():
	hp = 4
	reward = 2

	prev_global_position = $Standable.global_position

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
			var rect_global = $Shape.get_global_value()
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
			path_length = new_path.get_baked_length()
	path = new_path

	if debug:
		debug_path_color = Color(randf(), randf(), randf(), 1.0)

	w.emit_signal("finished_spawn_entities_step")

	await w.finished_spawning
	for node in get_tree().get_nodes_in_group("PhysicsProps"):
		if !node.has_node("BreakArea"): #Ignore all non-breakable prop
			$Standable.add_collision_exception_with(node)

func _physics_process(delta):
	if disabled || dead:
		return

	time += delta
	if time >= travel_time:
		if loop:
			time = wrapf(time, 0.0, travel_time)
		else:
			time = travel_time
			prev_global_position = $Standable.global_position
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


	var new_position = path.sample_baked(t_value * path_length)
	$Standable.global_position = new_position

	var moving_speed := path_length / travel_time
	var tolerance = min(moving_speed / 333.33, 1.0)
	moving_direction = new_position - prev_global_position
	moving_direction.x = sign(moving_direction.x) if abs(moving_direction.x) > tolerance else 0.0
	moving_direction.y = sign(moving_direction.y) if abs(moving_direction.y) > tolerance else 0.0

	if crushing:
		crush_check()

	animate()
	prev_global_position = new_position

func on_crush_body_entered(body):
	if !nearby_bodies.has(body):
		if body.get_collision_layer_value(5):
			if body.has_node("BreakArea"):
				nearby_bodies.append(body)
		else:
			nearby_bodies.append(body)

func on_crush_body_exited(body):
	if nearby_bodies.has(body):
		nearby_bodies.erase(body)

func crush_check():
	if moving_direction == Vector2.ZERO: return

	var crush_rect_size = $Standable/Crush/CollisionShape2D.shape.size
	var crush_rect := Rect2($Standable/Crush/CollisionShape2D.global_position - crush_rect_size / 2.0, crush_rect_size)
	var crush_rect_center := crush_rect.get_center()

	var physics_space = get_world_2d().direct_space_state

	for body in nearby_bodies:
		if body.get_collision_layer_value(1):
			body = body.get_parent()

		var body_is_breakable_prop = body.get_collision_layer_value(5)

		if body_is_breakable_prop:
			var raycheck_param: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
			raycheck_param.collision_mask = 8 #World / Prop
			raycheck_param.hit_from_inside = true
			raycheck_param.collide_with_bodies = true
			raycheck_param.collide_with_areas = false

			var move_dir_check_list := []
			if moving_direction.x != 0.0: move_dir_check_list.append(Vector2(moving_direction.x, 0.0))
			if moving_direction.y != 0.0: move_dir_check_list.append(Vector2(0.0, moving_direction.y))

			for curr_move_direction in move_dir_check_list:
				var checked_bodies := []
				var body_queue := [body]
				var success := false
				while !body_queue.is_empty():
					var curr_body = body_queue.pop_back()
					var curr_body_collision_shape = curr_body.get_node_or_null("CollisionShape2D")
					if !curr_body_collision_shape || curr_body_collision_shape.disabled:
						continue

					var curr_body_size = curr_body_collision_shape.shape.get_rect().size
					var root_check_position = curr_body.global_position + curr_body_size * 0.5 + curr_move_direction * curr_body_size * 0.5
					for check_direction in [curr_move_direction.rotated(-PI / 2.0), curr_move_direction.rotated(PI / 2.0)]:
						raycheck_param.from = root_check_position + check_direction * (curr_body_size - Vector2.ONE) * 0.5
						raycheck_param.to = raycheck_param.from + curr_move_direction * 0.5
						raycheck_param.exclude = [curr_body.get_rid(), $Standable.get_rid()]
						var collision = physics_space.intersect_ray(raycheck_param)
						if collision:
							var collider = collision["collider"]
							if collider is TileMapLayer || (collider.get_collision_layer_value(4) && !collider.has_node("BreakArea")):
								success = true
								body.on_break()
								break
							elif collider.has_node("BreakArea"):
								if !checked_bodies.has(collider):
									body_queue.append(collider)
					checked_bodies.append(curr_body)
					if success: break
				if success: break
		else:
			var body_collision_shape = body.get_node("CollisionShape2D")
			if !body_collision_shape || body_collision_shape.disabled:
				continue

			var body_size = body_collision_shape.shape.get_rect().size
			var body_rect := Rect2(body_collision_shape.global_position - body_size / 2.0, body_size)
			var body_overlap_rect := body_rect.intersection(crush_rect)

			if debug:
				debug_self_rect = crush_rect
				debug_body_rect = body_rect
				debug_over_rect = body_overlap_rect
				queue_redraw()

			if body_overlap_rect != Rect2():
				var body_position := body_overlap_rect.get_center()
				var check_direction := Vector2.ZERO
				var raycheck_position := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]

				const body_in_y_tolerance: = 3.0
				var body_in_y = body_position.y >= crush_rect.position.y + body_in_y_tolerance && body_position.y <= crush_rect.position.y + crush_rect.size.y - body_in_y_tolerance
				const body_in_x_tolerance: = 3.0
				var body_in_x = body_position.x >= crush_rect.position.x + body_in_x_tolerance && body_position.x <= crush_rect.position.x + crush_rect.size.x - body_in_x_tolerance

				const adjust := 1.0
				const adjust_2 := 3.0
				if body_in_y && moving_direction.x < 0.0 && body_position.x < crush_rect_center.x:
					check_direction.x = -1 - adjust_2
					raycheck_position.append(body_rect.position + Vector2(adjust_2, adjust))
					raycheck_position.append(body_rect.position + Vector2(adjust_2, body_rect.size.y / 2.0))
					raycheck_position.append(body_rect.position + Vector2(adjust_2, body_rect.size.y - adjust))
				elif body_in_y && moving_direction.x > 0.0 && body_position.x > crush_rect_center.x:
					check_direction.x = 1 + adjust_2
					raycheck_position.append(body_rect.position + Vector2(body_rect.size.x - adjust_2, adjust))
					raycheck_position.append(body_rect.position + Vector2(body_rect.size.x - adjust_2, body_rect.size.y / 2.0))
					raycheck_position.append(body_rect.position + Vector2(body_rect.size.x - adjust_2, body_rect.size.y - adjust))
				if body_in_x && moving_direction.y < 0.0 && body_position.y < crush_rect_center.y:
					check_direction.y = -1 - adjust_2
					raycheck_position.append(body_rect.position + Vector2(adjust, adjust_2))
					raycheck_position.append(body_rect.position + Vector2(body_rect.size.x / 2.0, adjust_2))
					raycheck_position.append(body_rect.position + Vector2(body_rect.size.x - adjust, adjust_2))
				elif body_in_x && moving_direction.y > 0.0 && body_position.y > crush_rect_center.y:
					check_direction.y = 1 + adjust_2
					raycheck_position.append(body_rect.position + Vector2(adjust, body_rect.size.y - adjust_2))
					raycheck_position.append(body_rect.position + Vector2(body_rect.size.x / 2.0, body_rect.size.y - adjust_2))
					raycheck_position.append(body_rect.position + Vector2(body_rect.size.x - adjust, body_rect.size.y - adjust_2))

				if check_direction == Vector2.ZERO: continue

				var collide_with_world := false
				for i in range(0, raycheck_position.size()):
					var raycheck_param := PhysicsRayQueryParameters2D.new()
					raycheck_param.from = raycheck_position[i]
					raycheck_param.to = raycheck_position[i] + check_direction
					raycheck_param.exclude = [body.get_rid(), $Standable.get_rid()]
					raycheck_param.collision_mask = 8
					raycheck_param.hit_from_inside = true
					raycheck_param.collide_with_bodies = true
					raycheck_param.collide_with_areas = false

					var collision = physics_space.intersect_ray(raycheck_param)
					while !collision.is_empty():
						var collider = collision["collider"]
						if collider.is_in_group("MovingPlatform"):
							var collider_move_direction = collider.get_parent().moving_direction
							if moving_direction.x * collider_move_direction.x < 0.0 || moving_direction.y * collider_move_direction.y < 0.0:
								collide_with_world = true
								break
							else:
								var exception = raycheck_param.exclude
								exception.append(collider.get_rid())
								raycheck_param.exclude = exception
								collision = physics_space.intersect_ray(raycheck_param)
						else:
							collide_with_world = true
							break
					if collide_with_world:
						break

				if collide_with_world:
					body.hit(999, Vector2.ZERO)
					body.die() # Pierce invis

@onready var ap = $AnimationPlayer
func animate():
	var move_angle = ($Standable.global_position - prev_global_position).angle()
	if ($Standable.global_position - prev_global_position).length() <= 0.01:
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
