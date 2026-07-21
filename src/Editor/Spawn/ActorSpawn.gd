extends Area2D

@export_file var actor_path := ""
@export var properties = {}
@export var tag_name: String = ""

var allow_spawn := true

@onready var w = get_tree().get_root().get_node("World")

func _draw() -> void:
	var actor = get_actor_name()
	if actor == "": return

	match actor:
		"Sentry":
			if properties["difficulty"][0] >= 3:
				var line_color = Color.RED
				var polygon_color = Color.CRIMSON
				polygon_color.a = 0.8
				var trans_polygon_color = polygon_color
				trans_polygon_color.a = 0.0
				var cone_length = 160.0
				var spread = properties["fountain_spread"][0] / 2.0
				var bullet_origin = Vector2(0.0, -12.0)
				var left_cone_point: Vector2 = bullet_origin + cone_length * Vector2.UP.rotated(-spread)
				var right_cone_point: Vector2 = bullet_origin + cone_length * Vector2.UP.rotated(spread)
				draw_dashed_line(bullet_origin, left_cone_point, line_color, 1.5, 3.0)
				draw_dashed_line(bullet_origin, right_cone_point, line_color, 1.5, 3.0)
				draw_polygon([bullet_origin, left_cone_point, right_cone_point], [polygon_color, trans_polygon_color, trans_polygon_color])
		"Crusher":
			const path_color := Color.RED
			const path_width := 2.0
			const point_color := Color.GREEN
			const point_radius := 5.0
			const point_inner_color := Color.WHITE
			const point_inner_radius := 3.0
			var path_type = properties["path_type"][0]
			match path_type:
				0: #Segment
					var to_point: Vector2 = $ToPoint.global_position - global_position
					var main_dir: Vector2 = to_point.normalized()
					var arrow_length = clamp(to_point.length() / 8.0, 8.0, 15.0)
					const arrow_angle = PI / 6.0
					if properties["loop"][0]:
						var move_from_center: Vector2 = 2.0 * main_dir.orthogonal()
						# To line
						draw_line(move_from_center, to_point + move_from_center, path_color, path_width)
						draw_line(move_from_center, move_from_center + main_dir.rotated(-arrow_angle) * arrow_length, path_color, path_width)
						draw_line(to_point + move_from_center, to_point + move_from_center - main_dir.rotated(arrow_angle) * arrow_length, path_color, path_width)
						# Reverse line
						draw_line(to_point - move_from_center, -move_from_center, path_color, path_width)
						draw_line(to_point - move_from_center, to_point - move_from_center - main_dir.rotated(-arrow_angle) * arrow_length, path_color, path_width)
						draw_line(-move_from_center, -move_from_center + main_dir.rotated(arrow_angle) * arrow_length, path_color, path_width)
					else:
						draw_line(Vector2.ZERO, to_point, path_color, path_width)
						draw_line(to_point, to_point - main_dir.rotated(arrow_angle) * arrow_length, path_color, path_width)
						draw_line(to_point, to_point - main_dir.rotated(-arrow_angle) * arrow_length, path_color, path_width)
				1: #Rectangle
					var new_path: Curve2D = Curve2D.new()
					var rect_global: Rect2 = $Shape.value
					new_path.add_point(rect_global.position)
					new_path.add_point(rect_global.position + Vector2(rect_global.size.x, 0.0))
					new_path.add_point(rect_global.position + rect_global.size)
					new_path.add_point(rect_global.position + Vector2(0.0, rect_global.size.y))
					new_path.add_point(rect_global.position)
					draw_rect($Shape.value, path_color, false, path_width)
					draw_circle(new_path.sample_baked(properties["non_segment_path_start"][0] * new_path.get_baked_length()), point_radius, point_color)
					draw_circle(new_path.sample_baked(properties["non_segment_path_start"][0] * new_path.get_baked_length()), point_inner_radius, point_inner_color)
				2: #Ellipse
					var new_path: Curve2D = Curve2D.new()
					var ellipse_a: float = $Shape.value.size.x / 2.0
					var ellipse_b: float = $Shape.value.size.y / 2.0
					var max_segment: float = max(TAU * (ellipse_a + ellipse_b) / 2.0 / 10.0, 40.0)
					var ellipse_center: Vector2 = $Shape.value.get_center()
					for i in range(0, max_segment):
						var curr_angle := float(i) * 2.0 * PI / max_segment
						var radius := ellipse_a * ellipse_b / sqrt(pow(ellipse_a * sin(curr_angle), 2) + pow(ellipse_b * cos(curr_angle), 2))
						var point_x := ellipse_center.x + radius * cos(curr_angle)
						var point_y := ellipse_center.y + radius * sin(curr_angle)
						new_path.add_point(Vector2(point_x, point_y))
					new_path.add_point(ellipse_center + Vector2(ellipse_a, 0))
					draw_ellipse($Shape.value.get_center(), ellipse_a, ellipse_b, path_color, false, path_width)
					draw_circle(new_path.sample_baked(properties["non_segment_path_start"][0] * new_path.get_baked_length()), point_radius, point_color)
					draw_circle(new_path.sample_baked(properties["non_segment_path_start"][0] * new_path.get_baked_length()), point_inner_radius, point_inner_color)

func _ready():
	if actor_path == "":
		printerr("ERROR: no actor chosen in ActorSpawn")
		return

	#groups
	if actor_path.begins_with("res://src/Actor/NPC/"):
		add_to_group("NPCSpawns")
	elif actor_path.begins_with("res://src/Actor/Enemy/"):
		add_to_group("EnemySpawns")

	var actor = load(actor_path).instantiate()
	actor.queue_free()

	#name
	var index = 0
	for a in get_tree().get_nodes_in_group("ActorSpawns"):
		if a == self: break
		if a.actor_path == actor_path:
			index +=1
	if index == 0:
		name = actor.name
	else:
		name = str(actor.name, index)

	#collision shape
	var collision_shape
	if actor.has_node("CollisionShape2D"):
		collision_shape = actor.get_node("CollisionShape2D")
	elif actor.has_node("Standable"):
		collision_shape = actor.get_node("Standable/CollisionShape2D")
	else:
		collision_shape = actor.get_child(0)
	$CollisionShape2D.shape = collision_shape.shape
	$CollisionShape2D.position = collision_shape.position

	if w.el.get_child_count() == 0: #not in editor
		visible = false
		input_pickable = false

func initialize(): #first time set up properties
	if (actor_path != ""):
		var actor = load(actor_path).instantiate()
		for p in actor.get_property_list():
			if p["usage"] & 4102 == 4102: #exported properties
				if p["name"] == "difficulty":
					print("set difficulty via initialize")
					properties[p["name"]] = [actor.get(p["name"]), TYPE_INT, ""]
				else:
					properties[p["name"]] = [actor.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]
		properties["id"] = [name, TYPE_STRING, ""]

		for ac in actor.get_children(): #TODO: add these to props and to waypoints
			if ac.is_in_group("WaypointLocals"):
				if !get_if_actor_has_waypoint(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
			if ac.is_in_group("WaypointGlobalSpawns"): #Not sure about this being here. what is this part realistically doing?
				if !get_if_actor_has_waypoint(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
			if ac.is_in_group("VUVectors"):
				if !get_if_actor_has_vu_vector(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
			if ac.is_in_group("VURects"):
				if !get_if_actor_has_vu_rect(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
			if ac.is_in_group("VUActors"):
				if !get_if_actor_has_vu_actor(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
		actor.free()

		set_sprite()
		for prop in properties: # init all special interaction when changing property
			on_property_changed(prop, properties[prop][0])

func reinitialize(): #makes sure properties are up to date and in the right order without deleting old values
	#print("re initialize")
	if (actor_path != ""):
		var old_properties = properties
		properties = {}
		var actor = load(actor_path).instantiate()
		for p in actor.get_property_list():
			if p["usage"] & 4102 == 4102: #exported properties
				if old_properties.has(p["name"]):
					if (old_properties[p["name"]].size() == 2): #Backward compability
						old_properties[p["name"]].append("")
					if p["hint"] == PROPERTY_HINT_ENUM && old_properties[p["name"]][2] != "":
						properties[p["name"]] = [old_properties[p["name"]][0], old_properties[p["name"]][1], p["hint_string"]]
					else:
						properties[p["name"]] = old_properties[p["name"]]
				else:
					properties[p["name"]] = [actor.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]

		for ac in actor.get_children():
			if ac.is_in_group("WaypointLocals"):
				if !get_if_actor_has_waypoint(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
			if ac.is_in_group("VUVectors"):
				if !get_if_actor_has_vu_vector(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
			if ac.is_in_group("VURects"):
				if !get_if_actor_has_vu_rect(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
			if ac.is_in_group("VUActors"):
				if !get_if_actor_has_vu_actor(ac):
					actor.remove_child(ac)
					ac.owner = null
					add_child(ac)
					ac.owner = w.current_level
		actor.free()

		set_sprite()
		for prop in properties: # init all special interaction when changing property
			on_property_changed(prop, properties[prop][0])

func spawn():
	if !allow_spawn:
		w.emit_signal.call_deferred("finished_spawn_entities_step")
		return
	if actor_path == "":
		printerr("ERROR: no actor chosen in ActorSpawn")
		w.emit_signal.call_deferred("finished_spawn_entities_step")
		return

	var actor = load(actor_path).instantiate()
	for p in properties:
		actor.set(p, properties[p][0])
	actor.name = name
	if properties["id"][0] == "": #no given id
		actor.id = name
	actor.global_position = global_position
	w.current_level.get_node("Actors").call_deferred("add_child", actor)

	for ac in actor.get_children(): #clear old from actor
		if ac.is_in_group("WaypointLocals") || ac.is_in_group("VUVectors") || ac.is_in_group("VURects") || ac.is_in_group("VUActors") || ac.is_in_group("WaypointGlobalSpawns"):
			actor.remove_child(ac)
			ac.queue_free()

	for c in get_children(): #add new from spawn
		if c.is_in_group("WaypointLocals") || c.is_in_group("VUVectors") || c.is_in_group("VURects") || c.is_in_group("VUActors"):
			var copy = c.duplicate()
			actor.add_child(copy)

### HELPERS ###

func set_sprite():
	var actor = load(actor_path).instantiate()
	actor.queue_free()
	if "difficulty" in actor:
		var texture_const_string = "TX_%s" % properties["difficulty"][0]
		$Sprite2D.texture = actor.get(texture_const_string)
	else:
		$Sprite2D.texture = actor.get_node("Sprite2D").texture
	$Sprite2D.hframes = actor.get_node("Sprite2D").hframes
	$Sprite2D.vframes = actor.get_node("Sprite2D").vframes
	$Sprite2D.frame = actor.get_node("Sprite2D").frame
	$Sprite2D.position = actor.get_node("Sprite2D").position

### GETTERS

func get_if_actor_has_waypoint(actor_waypoint) -> bool:
	var out = false
	for c in get_children():
		if c.is_in_group("WaypointLocals"): #q: does this need to apply for global spawns as well?
			if c.tag_name == actor_waypoint.tag_name:
				out = true
	return out

func get_if_actor_has_vu_vector(actor_vu_vector) -> bool:
	for c in get_children():
		if c.is_in_group("VUVectors"):
			if c.tag_name == actor_vu_vector.tag_name:
				return true
	return false

func get_if_actor_has_vu_rect(actor_vu_rect) -> bool:
	if !actor_vu_rect.value_changed.is_connected(on_vu_value_changed):
		actor_vu_rect.value_changed.connect(on_vu_value_changed)
	for c in get_children():
		if c.is_in_group("VURects"):
			if c.tag_name == actor_vu_rect.tag_name:
				if !c.value_changed.is_connected(on_vu_value_changed):
					c.value_changed.connect(on_vu_value_changed)
				return true
	return false

func get_if_actor_has_vu_actor(actor_vu_act) -> bool:
	for c in get_children():
		if c.is_in_group("VUActors"):
			if c.tag_name == actor_vu_act.tag_name:
				return true
	return false

### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)

func _input_event(_viewport, event, _shape_idx): #selecting in editor
	if w.get_node_or_null("EditorLayer/Editor"):
		var inspector = w.get_node("EditorLayer/Editor").inspector
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			inspector.on_selected(self, "actor_spawn")

func on_property_changed(p_name, p_value):
	var actor = get_actor_name()
	if actor == "": return

	if p_name == "difficulty":
		set_sprite()

	match actor:
		"Sentry":
			if p_name == "difficulty":
				$ShootX.visible = p_value < 2
				$ShootY.visible = p_value < 3
				queue_redraw()
			if p_name == "fountain_spread":
				queue_redraw()
		"Crusher":
			if p_name == "path_type":
				$ToPoint.visible = properties[p_name][0] == 0
				$Shape.visible = properties[p_name][0] != 0
			if p_name in ["path_type", "non_segment_path_reverse",
						 "non_segment_path_start", "loop"]:
				queue_redraw()

func on_vu_value_changed(tag, old_value, new_value):
	var actor = get_actor_name()
	if actor == "": return

	match actor:
		"Crusher":
			if tag == "shape_define": queue_redraw()

func get_actor_name() -> String:
	var file_path = actor_path
	if file_path.begins_with("uid://"):
		var uid = ResourceUID.text_to_id(actor_path)
		if !ResourceUID.has_id(uid):
			print("ActorSpawn | get_actor_name(): The provided actor_path doesn't have a corresponding UID")
			return ""
		file_path = ResourceUID.get_id_path(uid)

	if !file_path.is_absolute_path():
		print("ActorSpawn | get_actor_name(): actor_path is not a valid path!")
		return ""
	var actor = file_path.get_file()
	if actor.get_extension() != "tscn":
		print("ActorSpawn | get_actor_name(): actor_path does not point to a scene (.tscn) file!")
		return ""
	actor = actor.split(".")[0]
	return actor
