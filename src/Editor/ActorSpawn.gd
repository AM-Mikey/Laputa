extends Area2D

@export_file var actor_path
@export var properties = {}

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	if actor_path == null:
		printerr("ERROR: no actor chosen in ActorSpawn")
		return
	
	#groups
	if actor_path.begins_with("res://src/Actor/NPC/"):
		add_to_group("NPCSpawns")
	elif actor_path.begins_with("res://src/Actor/Enemy/"):
		add_to_group("EnemySpawns")
	
	
	#sprite
	var actor = load(actor_path).instantiate()
	$Sprite2D.texture = actor.get_node("Sprite2D").texture
	$Sprite2D.hframes = actor.get_node("Sprite2D").hframes
	$Sprite2D.vframes = actor.get_node("Sprite2D").vframes
	$Sprite2D.frame = actor.get_node("Sprite2D").frame
	$Sprite2D.position = actor.get_node("Sprite2D").position
	
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
	elif actor.has_hode("Standable"):
		collision_shape = actor.get_node("Standable/CollisionShape2D")
	$CollisionShape2D.shape = collision_shape.shape
	$CollisionShape2D.position = collision_shape.position

	if world.el.get_child_count() == 0: #not in editor
		visible = false
		input_pickable = false
		spawn()

func initialize(): #first time set up properties
	var actor = load(actor_path).instantiate()
	for p in actor.get_property_list():
		if p["usage"] == 4102: #exported properties
			properties[p["name"]] = [actor.get(p["name"]), p["type"]]

func spawn():
	if actor_path == null:
		printerr("ERROR: no actor chosen in ActorSpawn")
		return
	
	var actor = load(actor_path).instantiate()
	for p in properties:
		actor.set(p, properties[p][0])
	actor.name = name
	actor.global_position = global_position
	world.current_level.get_node("Actors").call_deferred("add_child", actor)



### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)


#func on_pressed(): #when
	#emit_signal("selected", self, "actor_spawn")

func _input_event(viewport, event, shape_idx): #selecting in editor
	var inspector = world.get_node("EditorLayer/Editor").inspector
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		inspector.on_selected(self, "actor_spawn")
