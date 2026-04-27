extends Node2D
class_name PhysWater

@export var water_size := Vector2(8.0, 16.0)
@export var surface_pos_y := 0.5
@export_range(2, 512) var segment_count := 64 #TODO: make this based on the water width

@export var player_splash_multiplier := 0.12
@export_range(0.0, 1000.0) var water_physics_speed := 80.0
@export var water_restoring_force := 0.02
@export var wave_energy_loss := 0.04
@export var wave_strength := 0.25
@export_range(1,64) var wave_spread_updates :=8

@export var surface_line_thickness := 1.0
@export var surface_color := Color.AQUA
@export var water_fill_color := Color.STEEL_BLUE

var segment_data := []
var recently_splashed := false

var surface_line: Line2D
var fill_polygon: Polygon2D

func _ready():
	for i in get_children():
		i.queue_free()

	_initiate_water()

func _initiate_water():
	segment_data.clear()
	for i in range(segment_count):
		segment_data.append({
			"height": surface_pos_y,
			"velocity": 0.0,
			"wave_to_left": 0.0,
			"wave_to_right": 0.0,
			})

	var line = Line2D.new()
	line.width = surface_line_thickness
	line.default_color = surface_color
	add_child(line)
	surface_line = line

	var polygon = Polygon2D.new()
	polygon.color = water_fill_color
	polygon.show_behind_parent = true
	surface_line.add_child(polygon)
	fill_polygon = polygon

	var area = Area2D.new()
	area.set_collision_layer_value(1, false) #i believe this defaults to true
	area.set_collision_mask_value(1, true) #just player for now
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)

	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = water_size
	collision_shape.shape = shape
	collision_shape.position = water_size / 2.0 + Vector2(0, surface_pos_y / 2.0)
	area.add_child(collision_shape)

func _process(delta: float):
	update_physics(delta)
	update_visuals()

func update_physics(delta):
	for i in range(segment_count):
		var displacement = segment_data[i]["height"] - surface_pos_y
		var acceleration = -water_restoring_force * displacement - segment_data[i]["velocity"] * wave_energy_loss

		segment_data[i]["velocity"] += acceleration * delta * water_physics_speed
		segment_data[i]["height"] += segment_data[i]["velocity"] * delta * water_physics_speed

	for updates in range(wave_spread_updates):
		for i in range(segment_count):
			if i > 0:
				segment_data[i]["wave_to_left"] = (segment_data[i]["height"] - segment_data[i-1]["height"] * wave_strength)
				segment_data[i-1]["velocity"] += segment_data[i]["wave_to_left"] * delta * water_physics_speed
			if i < segment_count - 1:
				segment_data[i]["wave_to_right"] = (segment_data[i]["height"] - segment_data[i+1]["height"] * wave_strength)
				segment_data[i+1]["velocity"] += segment_data[i]["wave_to_right"] * delta * water_physics_speed

		#for i in range(segment_count):
			#if i > 0:
				#segment_data[i]["wave_to_left"] = (segment_data[i]["height"] - segment_data[i-1]["height"] * wave_strength)
				#segment_data[i-1]["velocity"] += segment_data[i]["wave_to_left"] * delta * water_physics_speed
			#if i < segment_count - 1:
				#segment_data[i]["wave_to_right"] = (segment_data[i]["height"] - segment_data[i+1]["height"] * wave_strength)
				#segment_data[i-1]["velocity"] += segment_data[i]["wave_to_right"] * delta * water_physics_speed

		for i in range(segment_count):
			if i > 0:
				segment_data[i-1]["height"] += segment_data[i]["wave_to_left"] * delta * water_physics_speed
			if i < segment_count - 1:
				segment_data[i+1]["height"] += segment_data[i]["wave_to_right"] * delta * water_physics_speed

	segment_data[0]["height"] = surface_pos_y
	segment_data[1]["height"] = surface_pos_y
	segment_data[0]["velocity"] = 0.0
	segment_data[1]["velocity"] = 0.0

	segment_data[segment_count - 1]["height"] = surface_pos_y
	segment_data[segment_count - 2]["height"] = surface_pos_y
	segment_data[segment_count - 1]["velocity"] = 0.0
	segment_data[segment_count - 2]["velocity"] = 0.0

	if !recently_splashed:
		var is_still := true
		for i in surface_line.points:
			if abs(abs(i.y) - abs(surface_pos_y)) > 0.001:
				is_still = false
				break
		set_process(!is_still)
	else:
		recently_splashed = false

func update_visuals():
	var points: Array[Vector2] = []
	var segment_width: float = water_size.x / (segment_count - 1)
	for i in range(segment_count):
		points.append(Vector2(i * segment_width, segment_data[i]["height"]))

	var left_static_point := Vector2(points[0].x, surface_pos_y)
	var right_static_point := Vector2(points[points.size()-1].x, surface_pos_y)

	var final_points: Array[Vector2] = []
	final_points.append(left_static_point)
	final_points += points
	final_points.append(right_static_point)

	surface_line.points = final_points

	var bottom_y: float = surface_pos_y + water_size.y
	final_points.append(Vector2(water_size.x, bottom_y))
	final_points.append(Vector2(0, bottom_y))
	fill_polygon.polygon = final_points

func splash(splash_pos: Vector2, splash_velocity: float):
	var local_x_pos: float = to_local(splash_pos).x
	var segment_width: float = water_size.x / (segment_count - 1)
	var index := int(clamp(local_x_pos / segment_width, 0, segment_count - 1))
	segment_data[index]["velocity"] = splash_velocity
	recently_splashed = true
	set_process(true)

func _get_body_velocity_y(body: Node) -> float:
	if body is CharacterBody2D:
		return body.velocity.y
	elif body is RigidBody2D:
		return body.linear_velocity.y
	return 0.0

### SIGNALS ###

func _on_body_entered(body): #TODO: expand to other things besides just player, put this on juniper's physics shape instead
	if body.get_parent().get_collision_layer_value(1): #player
		var target = body.get_parent()
		var vy := _get_body_velocity_y(body)
		splash(target.global_position, -vy * player_splash_multiplier)

func _on_body_exited(body):
	if body.get_parent().get_collision_layer_value(1): #player
		var target = body.get_parent()
		var vy := _get_body_velocity_y(body)
		splash(target.global_position,  vy * player_splash_multiplier)
