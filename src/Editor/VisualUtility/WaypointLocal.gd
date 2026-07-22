extends Area2D

signal selected(waypoint_local, type)

@export var tag_name: String
@export var index: int = 0
@export var lock_x: bool = false
@export var lock_y: bool = false

var active_count = 0

var prev_global_position
signal value_changed(what, old_val, val)

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	if w.el.get_child_count() == 0: #not in editor
		visible = false
		input_pickable = false

func _process(_delta):
	if w.el.get_child_count() > 0:
		if (prev_global_position != global_position):
			value_changed.emit(self, prev_global_position, global_position)
		prev_global_position = global_position

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
