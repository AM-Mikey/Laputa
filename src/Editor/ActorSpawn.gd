extends Area2D

signal selected(actor_spawn, type)

@export_file var actor_path
@onready var world = get_tree().get_root().get_node("World")



func _ready():
	add_to_group("Entities")
	add_to_group("ActorSpawns")
	if actor_path == null:
		printerr("ERROR: no actor chosen in ActorSpawn")
		return
	var actor = load(actor_path).instantiate()
	$Sprite2D.texture = actor.get_node("Sprite2D").texture
	$Sprite2D.hframes = actor.get_node("Sprite2D").hframes
	$Sprite2D.vframes = actor.get_node("Sprite2D").vframes
	$Sprite2D.frame = actor.get_node("Sprite2D").frame
	$Sprite2D.position = actor.get_node("Sprite2D").position
	
	var collision_shape
	if actor.has_node("CollisionShape2D"):
		collision_shape = actor.get_node("CollisionShape2D")
	elif actor.has_hode("Standable"):
		collision_shape = actor.get_node("Standable/CollisionShape2D")
	$CollisionShape2D.shape = collision_shape.shape
	$CollisionShape2D.position = collision_shape.position
	
	if world.el.get_child_count() == 0: #not in editor
		visible = false
		spawn()

func spawn():
	if actor_path == null:
		printerr("ERROR: no actor chosen in ActorSpawn")
		return
	
	var actor = load(actor_path).instantiate()
	actor.global_position = global_position
	world.current_level.get_node("Actors").add_child(actor)



### SIGNALS

func on_editor_select():
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)


func on_pressed():
	emit_signal("selected", self, "actor_spawn")

func _input_event(viewport, event, shape_idx): #selecting in editor
	var editor = world.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, "actor_spawn")
