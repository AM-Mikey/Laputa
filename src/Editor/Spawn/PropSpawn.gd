extends Area2D

@export_file var prop_path
@export var properties = {}

var allow_spawn := true
var physics_prop_spawn_distance = 0.001

@onready var w = get_tree().get_root().get_node("World")

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
	properties["id"] = [name, TYPE_STRING]
	for ac in prop.get_children():
		if ac.is_in_group("WaypointLocals"):
			if !get_if_prop_has_waypoint(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("WaypointGlobalSpawns"):
			if !get_if_prop_has_waypoint(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUVectors"):
			if !get_if_prop_has_vu_vector(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VURects"):
			if !get_if_prop_has_vu_rect(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUActors"):
			if !get_if_prop_has_vu_actor(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
	prop.free()

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
	for ac in prop.get_children():
		if ac.is_in_group("WaypointLocals"):
			if !get_if_prop_has_waypoint(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("WaypointGlobalSpawns"):
			if !get_if_prop_has_waypoint(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUVectors"):
			if !get_if_prop_has_vu_vector(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VURects"):
			if !get_if_prop_has_vu_rect(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("VUActors"):
			if !get_if_prop_has_vu_actor(ac):
				prop.remove_child(ac)
				ac.owner = null
				add_child(ac)
				ac.owner = w.current_level
	prop.free()

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
		if ac.is_in_group("WaypointLocals") || ac.is_in_group("VUVectors") || ac.is_in_group("VURects") || ac.is_in_group("VUActors"):
			prop.remove_child(ac)
		if ac.is_in_group("WaypointGlobalSpawns"): #turn off visibility
			ac.visible = false

	for c in get_children(): #add new from spawn
		if c.is_in_group("WaypointLocals") || c.is_in_group("VUVectors") || c.is_in_group("VURects") || c.is_in_group("VUActors"):
			var copy = c.duplicate()
			prop.add_child(copy)

	w.current_level.get_node("Props").call_deferred("add_child", prop)

### GETTERS

func get_if_prop_has_waypoint(waypoint) -> bool:
	var out = false
	for c in get_children():
		if c.is_in_group("WaypointLocals"): #q: does this need to apply for global spawns as well?
			if c.tag_name == waypoint.tag_name:
				out = true
	return out

func get_if_prop_has_vu_vector(vu_vector) -> bool:
	for c in get_children():
		if c.is_in_group("VUVectors"):
			if c.tag_name == vu_vector.tag_name:
				return true
	return false

func get_if_prop_has_vu_rect(vu_rect) -> bool:
	for c in get_children():
		if c.is_in_group("VURects"):
			if c.tag_name == vu_rect.tag_name:
				return true
	return false

func get_if_prop_has_vu_actor(vu_actor) -> bool:
	for c in get_children():
		if c.is_in_group("VUActors"):
			if c.tag_name == vu_actor.tag_name:
				return true
	return false


### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)


func _input_event(_viewport, event, _shape_idx): #selecting in editor
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		var inspector = w.get_node("EditorLayer/Editor").inspector
		inspector.on_selected(self, "prop_spawn")

func on_property_changed(p_name, p_value):
	pass
