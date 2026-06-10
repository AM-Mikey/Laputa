extends Area2D

@export_file var actor_path := "":
	set(val):
		actor_path = val
		if is_model:
			if (FileAccess.file_exists(actor_path)):
				var actor = load(actor_path).instantiate()

				var collision_shape
				if actor.has_node("CollisionShape2D"):
					collision_shape = actor.get_node("CollisionShape2D")
				elif actor.has_node("Standable"):
					collision_shape = actor.get_node("Standable/CollisionShape2D")
				else:
					collision_shape = actor.get_child(0)
				$CollisionShape2D.shape = collision_shape.shape
				$CollisionShape2D.position = collision_shape.position
			else:
				var new_shape: RectangleShape2D = RectangleShape2D.new()
				new_shape.size = Vector2i(16, 16)
				$CollisionShape2D.shape = new_shape
				$CollisionShape2D.position = new_shape.size / 2.0

@export var properties = {}
## If true, become an UI to customize Actor for Trigger + disable spawning
@export var is_model: bool = false
@export var tag_name: String = ""

@onready var w = get_tree().get_root().get_node("World")


func _ready():
	if is_model:
		actor_path = actor_path
	else:
		if actor_path == "":
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

func initialize(): #first time set up properties
	print("initialize")
	if (actor_path != ""):
		var actor = load(actor_path).instantiate()
		for p in actor.get_property_list():
			if p["usage"] & 4102 == 4102: #exported properties
				if p["name"] == "difficulty":
					properties[p["name"]] = [actor.get(p["name"]), TYPE_INT, ""]
				else:
					properties[p["name"]] = [actor.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]
		properties["id"] = [name, TYPE_STRING, ""]
		set_sprite()


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
		actor.free()

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
					properties[p["name"]] = old_properties[p["name"]]
				else:
					properties[p["name"]] = [actor.get(p["name"]), p["type"], p["hint_string"] if p["hint"] == PROPERTY_HINT_ENUM else ""]
		set_sprite()

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
		actor.free()

func spawn():
	if is_model:
		w.emit_signal.call_deferred("finished_spawn_entities_step")
		return
	if actor_path == "":
		printerr("ERROR: no actor chosen in ActorSpawn")
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
		if ac.is_in_group("WaypointLocals") || ac.is_in_group("VUVectors") || ac.is_in_group("VURects") || ac.is_in_group("WaypointGlobalSpawns"):
			actor.remove_child(ac)

	for c in get_children(): #add new from spawn
		if c.is_in_group("WaypointLocals") || c.is_in_group("VUVectors") || c.is_in_group("VURects"):
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

func get_if_actor_has_vu_vector(actor_vu_vector) -> bool:
	for c in get_children():
		if c.is_in_group("VUVectors"):
			if c.tag_name == actor_vu_vector.tag_name:
				return true
	return false

func get_if_actor_has_vu_rect(actor_vu_rect) -> bool:
	for c in get_children():
		if c.is_in_group("VURects"):
			if c.tag_name == actor_vu_rect.tag_name:
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
