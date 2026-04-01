extends Area2D

signal selected(waypoint_local, type)

@export var tag_name: String
@export var index: int = 0

var active_count = 0

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	visible = w.debug_visible or w.el.get_child_count() > 0

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
