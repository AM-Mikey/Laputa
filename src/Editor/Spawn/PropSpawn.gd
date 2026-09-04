extends Area2D

@export_file var prop_path
@export var properties = {}

var allow_spawn := true
var physics_prop_spawn_distance = 0.001

@onready var w = get_tree().get_root().get_node("World")

func _draw():
	var prop = get_prop_name()
	if prop == "": return

	match prop:
		"PhysFan":
			var from_point = Vector2(8.0, 8.0)
			var to_point = $Distance.position
			var color = Color.CYAN
			var width = 2.0
			color.a = 0.4
			draw_line(from_point, to_point, color, width)
			draw_arrow(to_point, $Distance.position.normalized(), 8.0, PI / 6.0, color, width)

func draw_arrow(pos: Vector2, dir: Vector2, arrow_length: float, arrow_angle: float, color: Color, width: float = -1.0):
	draw_line(pos, pos - dir.rotated(arrow_angle) * arrow_length, color, width)
	draw_line(pos, pos - dir.rotated(-arrow_angle) * arrow_length, color, width)

func _ready():
	if prop_path == null:
		printerr("ERROR: no prop chosen in PropSpawn")
		return
	add_to_group("PropSpawns")

	#sprite
	var prop = load(prop_path).instantiate()
	prop.queue_free()
	$Sprite2D.texture = prop.get_node("Sprite2D").texture
	$Sprite2D.hframes = prop.get_node("Sprite2D").hframes
	$Sprite2D.vframes = prop.get_node("Sprite2D").vframes
	$Sprite2D.frame = prop.get_node("Sprite2D").frame
	$Sprite2D.position = prop.get_node("Sprite2D").position

	#name
	var index = 0
	for p in get_tree().get_nodes_in_group("PropSpawns"):
		if p == self: break
		if p.prop_path == prop_path:
			index +=1
	if index == 0:
		name = prop.name
	else:
		name = str(prop.name, index)

	#collision shape
	var collision_shape
	if prop.has_node("EditorArea/CollisionShape2D"):
		collision_shape = prop.get_node("EditorArea/CollisionShape2D")
	else:
		printerr("ERROR: PROP NEEDS NODE: EditorArea/CollisionShape2D")
	$CollisionShape2D.shape = collision_shape.shape
	$CollisionShape2D.position = collision_shape.position

	if w.el.get_child_count() == 0: #not in editor
		visible = false
		input_pickable = false

func initialize(): #first time set up properties
	var prop = load(prop_path).instantiate()
	for p in prop.get_property_list():
		if p["usage"] == 4102 || p["usage"] == 69638: #exported properties
			properties[p["name"]] = [prop.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]
	properties["id"] = [name, TYPE_STRING, ""]

	setup_vus(prop)
	prop.free()
	for p in properties: # init all special interaction when changing property
		on_property_changed(p, properties[p][0])


func reinitialize(): #makes sure properties are up to date and in the right order without deleting old values
	var old_properties = properties
	properties = {}
	var prop = load(prop_path).instantiate()
	for p in prop.get_property_list():
		if p["usage"] == 4102 || p["usage"] == 69638: #exported properties
			if old_properties.has(p["name"]):
				properties[p["name"]] = old_properties[p["name"]]
			else:
				properties[p["name"]] = [prop.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]

	setup_vus(prop)
	prop.free()
	for p in properties: # init all special interaction when changing property
		on_property_changed(p, properties[p][0])

func spawn():
	if !allow_spawn: return
	if prop_path == null:
		printerr("ERROR: no prop chosen in PropSpawn")
		return

	var prop = load(prop_path).instantiate()
	for p in properties:
		prop.set(p, properties[p][0])
	prop.name = name
	if prop.is_in_group("PhysicsProps"):
		prop.global_position = Vector2(global_position.x, global_position.y - physics_prop_spawn_distance) #so that they don't clip through one-ways
	else:
		prop.global_position = global_position

	for ac in prop.get_children(): #clear old from trigger
		if ac.is_in_group("VisualUtilities"):
			prop.remove_child(ac)
			ac.queue_free()

	for c in get_children(): #add new from spawn
		if c.is_in_group("VisualUtilities") && !c.is_in_group("WaypointGlobalSpawns"):
			var copy = c.duplicate()
			prop.add_child(copy)

	w.current_level.get_node("Props").call_deferred("add_child", prop)


### HELPERS
func setup_vus(prop):
	var vu_groups = ["WaypointLocals", "WaypointGlobalSpawns", "VUVectors", "VURects", "VUActors"]
	for i in prop.get_children():
		for vu_group in vu_groups:
			if i.is_in_group(vu_group):
				if !get_if_prop_has_visual_utility(i, vu_group):
					prop.remove_child(i)
					i.owner = null
					add_child(i)
					i.owner = w.current_level
	for j in get_children():
		if j.is_in_group("VisualUtilities"):
			if j.has_signal("value_changed") && !j.value_changed.is_connected(on_vu_value_changed):
				j.value_changed.connect(on_vu_value_changed)



### GETTERS
func get_if_prop_has_visual_utility(actor_waypoint, group) -> bool:
	var out = false
	for c in get_children():
		if c.is_in_group(group):
			if c.tag_name == actor_waypoint.tag_name:
				out = true
	return out



### SIGNALS

func on_editor_select(): #when
	modulate = Color.RED

func on_editor_deselect():
	modulate = Color(1,1,1)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if w.get_node_or_null("EditorLayer/Editor"):
		var inspector = w.get_node("EditorLayer/Editor").inspector
		if event.is_action_pressed("editor_rmb"):
			inspector.on_selected(self, "prop_spawn")

func on_property_changed(p_name, p_value):
	var prop = get_prop_name()
	if prop == "": return

			

func on_vu_value_changed(vu, _old_value, new_value):
	var prop = get_prop_name()
	if prop == "": return

	match prop:
		"PhysFan":
			if vu.is_in_group("VUVectors") and vu.tag_name == "wind_dir":
				var distance_waypoint = $Distance
				var true_wp_pos = $Distance.position - Vector2(8.0, 8.0) - 8.0 * new_value
				var curr_distance = true_wp_pos.length()
				
				var is_dir_vertical = new_value.snappedf(1.0) in [Vector2.UP, Vector2.DOWN]
				distance_waypoint.lock_x = is_dir_vertical
				distance_waypoint.lock_y = !is_dir_vertical
				distance_waypoint.position = (curr_distance + 8.0) * new_value + Vector2(8.0, 8.0)
				queue_redraw()
			elif vu.is_in_group("WaypointLocals") and vu.tag_name == "distance":
				queue_redraw()

func get_prop_name() -> String:
	var file_path = prop_path
	if file_path.begins_with("uid://"):
		var uid = ResourceUID.text_to_id(prop_path)
		if !ResourceUID.has_id(uid):
			print("ActorSpawn | get_actor_name(): The provided actor_path doesn't have a corresponding UID")
			return ""
		file_path = ResourceUID.get_id_path(uid)

	if !file_path.is_absolute_path():
		print("ActorSpawn | get_actor_name(): actor_path is not a valid path!")
		return ""
	var actor = file_path.get_file()
	if actor.get_extension() != "tscn":
		printerr("ActorSpawn | get_actor_name(): actor_path does not point to a scene (.tscn) file!")
		return ""
	actor = actor.split(".")[0]
	return actor
