extends Area2D

@export var owner_id: String
@export var tag_name: String
@export var index : int = 0
var uses_spawn := false
var active_count = 0

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	visible = w.debug_visible or w.el.get_child_count() > 0


func activate():
	active_count += 1
	set_color()

func deactivate():
	active_count -= 1
	set_color()

func set_color():
	match active_count:
		0: modulate = Color(1,1,1)
		1: modulate = Color.RED
		2: modulate = Color.DARK_RED
		3: modulate = Color.DARK_MAGENTA
		4: modulate = Color.DARK_BLUE
		_: modulate = Color.BLACK

### SIGNALS

func on_editor_select():
	$Sprite2D.modulate = Color.RED

func on_editor_deselect():
	$Sprite2D.modulate = Color(1,1,1)

func _input_event(_viewport, event, _shape_idx): #selecting in editor
	var editor = w.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, "waypoint_local")
