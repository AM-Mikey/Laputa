extends Area2D

signal selected(vanishing_point, type)

@export var tag_name: String
@export var index: int = 0
var owner_id: String
#var owner_node: Node
var active_count = 0

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	visible = w.debug_visible
	editor_exit()

func editor_enter():
	var saved_pos = global_position
	get_parent().remove_child.call_deferred(self)
	for e in get_tree().get_nodes_in_group("EnemySpawns"): #TODO: expand to all used groups
		if e.properties["id"][0] == owner_id:
			e.add_child.call_deferred(self)
			global_position = saved_pos - e.global_position

func editor_exit(): #TODO: we need a good way to delete the initial WPLGs when we enter so we can use the ones from the actor instead
	print("editor exit")
	if "id" in get_parent():
		owner_id = get_parent().id
	#var saved_pos = global_position #TODO: uncomment this
	#get_parent().remove_child.call_deferred(self)
	#w.current_level.get_node("Waypoints").add_child.call_deferred(self)
	#await get_tree().physics_frame #we could use a signal instead. this frame may cause issues with load order
	#global_position = saved_pos


### SIGNALS

func on_editor_select():
	$Sprite2D.modulate = Color.RED

func on_editor_deselect():
	$Sprite2D.modulate = Color.FOREST_GREEN

func on_pressed():
	emit_signal("selected", self, "waypoint_local")

func _input_event(_viewport, event, _shape_idx): #selecting in editor
	var editor = w.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, "waypoint_local")
