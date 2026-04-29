extends Node2D

@export var water_size := Vector2(8.0, 16.0)
@export var surface_pos_y := 0.5
var segment_count: int

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
	_initiate_water()

func _initiate_water():
	segment_count = int(water_size.x / 2.0)
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

	#area
	%SplashDetector/CollisionShape2D.shape.size = water_size
	%SplashDetector/CollisionShape2D.position = water_size / 2.0 + Vector2(0, surface_pos_y / 2.0)

func _process(delta: float) -> void:
	update_physics(delta)
	update_visuals()

func update_physics(delta) -> void:
	for i in range(segment_count):
		var displacement = segment_data[i]["height"] - surface_pos_y
		var acceleration = -water_restoring_force * displacement - segment_data[i]["velocity"] * wave_energy_loss

		segment_data[i]["velocity"] += acceleration * delta * water_physics_speed
		segment_data[i]["height"] += segment_data[i]["velocity"] * delta * water_physics_speed

	for updates in range(wave_spread_updates):
		for i in range(segment_count):
			if i > 0:
				segment_data[i]["wave_to_left"] = (segment_data[i]["height"] - segment_data[i-1]["height"]) * wave_strength
				segment_data[i-1]["velocity"] += segment_data[i]["wave_to_left"] * delta * water_physics_speed
			if i < segment_count - 1:
				segment_data[i]["wave_to_right"] = (segment_data[i]["height"] - segment_data[i+1]["height"]) * wave_strength
				segment_data[i+1]["velocity"] += segment_data[i]["wave_to_right"] * delta * water_physics_speed
			#print(segment_data[i]["height"])
			#print(" ")

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

func update_visuals() -> void:
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
	print("doing_splash")
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

func _on_SplashDetector_body_entered(body: Node2D): #need to stop this triggering if we just spawned it this frame
	#print("body_enter")

	if body.get_collision_layer_value(16): #rigidbody
		if body.just_spawned:
			print("body just spawned in water, ignoring splash")
			return
		print("entered")
		var target = body.get_parent()
		var vy := _get_body_velocity_y(target)
		splash(target.global_position, -vy * player_splash_multiplier)


func _on_SplashDetector_body_exited(body: Node2D):
	if body.get_collision_layer_value(16):
		var target = body.get_parent()
		if "is_fizzling" in target:
			if target.is_fizzling:
				print("bullet fizzled in water, ignoring splash")
				return
		print("exited")
		var vy := _get_body_velocity_y(target)
		splash(target.global_position, vy * player_splash_multiplier)
