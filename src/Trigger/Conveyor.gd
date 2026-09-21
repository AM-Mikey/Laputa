extends Trigger

const CONVEYOR_SEGMENT = preload("res://src/Prop/ConveyorSegment.tscn")

@export var toggled := true
@export var move_dir := Vector2.LEFT
@export var speed := 10.0
@export var switch_reverses = false

var segments = []

func _ready(): #Reminder: no function called can use await
	trigger_type = "conveyor"

	var points := get_grid_points()
	var min_x := INF
	var max_x := -INF
	for g in points:
		min_x = min(min_x, g.x)
		max_x = max(max_x, g.x)
	for g in points:
		var conveyor_segment = CONVEYOR_SEGMENT.instantiate()
		conveyor_segment.trigger_parent = self
		conveyor_segment.toggled = toggled
		conveyor_segment.direction = move_dir
		conveyor_segment.speed = speed
		conveyor_segment.global_position = g
		if g.x == min_x:
			conveyor_segment.segment = "left"
		elif g.x == max_x:
			conveyor_segment.segment = "right"
		else:
			conveyor_segment.segment = "middle"
		segments.append(conveyor_segment)
		w.current_level.get_node("Props").add_child(conveyor_segment)
	w.emit_signal("finished_spawn_entities_step")

### GETTER ###

func get_grid_points() -> Array:
	var points: Array = []
	var shape_node := $CollisionShape2D as CollisionShape2D
	var shape := shape_node.shape as RectangleShape2D
	# World-space AABB
	var half_size: Vector2 = shape.size / 2.0
	var top_left: Vector2 = shape_node.global_position - half_size
	var bottom_right: Vector2 = shape_node.global_position + half_size
	#include top and left
	var start_x: float = ceil(top_left.x / 16.0) * 16.0
	var start_y: float = ceil(top_left.y / 16.0) * 16.0
	#exclude bottom and right
	var x := start_x
	while x < bottom_right.x:
		var y := start_y
		while y < bottom_right.y:
			points.append(Vector2(x, y))
			y += 16.0
		x += 16.0
	return points



### SIGNALS ###

func on_switch_toggled(switch_toggled):
	if switch_reverses:
		move_dir.x *= -1
		for s in segments:
			if s != null:
				s.direction = move_dir
				s.update_segment()
	else:
		toggled = switch_toggled
		for s in segments:
			if s != null:
				s.toggled = toggled
				s.update_segment()
	#sound
	#visual spark
	#shake
	#rumble
	if toggled:
		pass
	else:
		pass

func on_switch_timer_start():
	if switch_reverses:
		move_dir.x *= -1
		for s in segments:
			if s != null:
				s.direction = move_dir
				s.update_segment()
	else:
		toggled = true
		for s in segments:
			if s != null:
				s.toggled = toggled
				s.update_segment()

func on_switch_timer_timeout():
	if switch_reverses:
		move_dir.x *= -1
		for s in segments:
			if s != null:
				s.direction = move_dir
				s.update_segment()
	else:
		toggled = false
		for s in segments:
			if s != null:
				s.toggled = toggled
				s.update_segment()
