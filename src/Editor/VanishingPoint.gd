extends Area2D

signal selected(vanishing_point, type)

@export var zoom := 4.0

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	visible = false

func _physics_process(_delta: float):
	$BackgroundOutline.size = Vector2(480, 270) * 4 / zoom
	$BackgroundOutline.position = $BackgroundOutline.size / -2.0

### SIGNALS

func on_editor_select():
	self_modulate = Color.RED
	$BackgroundOutline.modulate = Color(0.0, 1.0, 1.0, 1.0)

func on_editor_deselect():
	self_modulate = Color(1,1,1)
	$BackgroundOutline.modulate = Color(0.0, 1.0, 1.0, 0.5)

func on_pressed():
	emit_signal("selected", self, "title_preview")

func _input_event(_viewport, event, _shape_idx): #selecting in editor
	var editor = world.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, "title_preview")
