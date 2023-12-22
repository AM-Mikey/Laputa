extends Area2D

signal selected(spawn_point, type)

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("SpawnPoints")
	visible = false

### SIGNALS

func on_editor_select():
	modulate = Color.RED

func on_editor_deselect():
	modulate = Color(1,1,1)


func on_pressed():
	emit_signal("selected", self, "spawn_point")

func _input_event(viewport, event, shape_idx): #selecting in editor
	var editor = world.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, "spawn_point")
