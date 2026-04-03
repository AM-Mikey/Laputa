extends Area2D

@export_file var actor_path
@export var properties = {}

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	if actor_path == null:
		printerr("ERROR: no actor chosen in ActorSpawn")
		return

	#groups
	if actor_path.begins_with("res://src/Actor/NPC/"):
		add_to_group("NPCSpawns")
	elif actor_path.begins_with("res://src/Actor/Enemy/"):
		add_to_group("EnemySpawns")


	var actor = load(actor_path).instantiate()

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
		spawn()

func initialize(): #first time set up properties
	#print("initialize")
	var actor = load(actor_path).instantiate()
	for p in actor.get_property_list():
		if p["usage"] == 4102 || p["usage"] == 69638: #exported properties
			if p["name"] == "difficulty":
				pass #we set this when creating the actorspawn
			else:
				properties[p["name"]] = [actor.get(p["name"]), p["type"]]
	properties["id"] = [name, TYPE_STRING]
	set_sprite()

	for ac in actor.get_children(): #TODO: add these to props and to waypoints
		if ac.is_in_group("WaypointLocals"):
			if !get_if_actor_has_waypoint(ac):
				actor.remove_child(ac)
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("WaypointGlobalSpawns"):
			if !get_if_actor_has_waypoint(ac):
				actor.remove_child(ac)
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("ToolVectors"):
			if !get_if_actor_has_tool_vector(ac):
				actor.remove_child(ac)
				add_child(ac)
				ac.owner = w.current_level
	actor.free()

func reinitialize(): #makes sure properties are up to date and in the right order without deleting old values
	#print("re initialize")
	var old_properties = properties
	properties = {}
	var actor = load(actor_path).instantiate()
	for p in actor.get_property_list():
		if p["usage"] == 4102 || p["usage"] == 69638: #exported properties
			if old_properties.has(p["name"]):
				properties[p["name"]] = old_properties[p["name"]]
			else:
				properties[p["name"]] = [actor.get(p["name"]), p["type"]]
	set_sprite()

	for ac in actor.get_children():
		if ac.is_in_group("WaypointLocals"):
			if !get_if_actor_has_waypoint(ac):
				actor.remove_child(ac)
				add_child(ac)
				ac.owner = w.current_level
		if ac.is_in_group("ToolVectors"):
			if !get_if_actor_has_tool_vector(ac):
				actor.remove_child(ac)
				add_child(ac)
				ac.owner = w.current_level
	actor.free()

func spawn():
	#print("spawn")
	if actor_path == null:
		printerr("ERROR: no actor chosen in ActorSpawn")
		return

	var actor = load(actor_path).instantiate()
	for p in properties:
		actor.set(p, properties[p][0])
	actor.name = name
	if properties["id"][0] == "": #no given id
		actor.id = name
	actor.global_position = global_position
	await w.current_level.get_node("Actors").call_deferred("add_child", actor)

	for ac in actor.get_children(): #clear old from actor
		if ac.is_in_group("WaypointLocals") || ac.is_in_group("ToolVectors"):
			actor.remove_child(ac)
		if ac.is_in_group("WaypointGlobalSpawns"): #turn off visibility
			ac.visible = false

	for c in get_children(): #add new from spawn
		if c.is_in_group("WaypointLocals") || c.is_in_group("ToolVectors"):
			var copy = c.duplicate()
			actor.add_child(copy)

### HELPERS ###

func set_sprite():
	var actor = load(actor_path).instantiate()
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

func get_if_actor_has_tool_vector(actor_tool_vector) -> bool:
	for c in get_children():
		if c.is_in_group("ToolVectors"):
			if c.tag_name == actor_tool_vector.tag_name:
				return true
	return false

### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)


func _input_event(_viewport, event, _shape_idx): #selecting in editor
	var inspector = w.get_node("EditorLayer/Editor").inspector
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		inspector.on_selected(self, "actor_spawn")
