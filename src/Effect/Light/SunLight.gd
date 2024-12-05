extends Area2D

@onready var w = get_tree().get_root().get_node("World")


@export var light_color = Color(0.5, 0.5, 0.5)
@export var shadow_color = Color(0, 0, 0)
@export var modulate_color = Color(0.5, 0.5, 0.5)

func _ready():
	editor_exit()
	setup_colors()

func setup_colors():
	$PointLight2D.color = light_color
	$PointLight2D.shadow_color = shadow_color
	$CanvasModulate.color = modulate_color

func _input_event(viewport, event, shape_idx): #selecting in editor
	var editor = w.get_node("EditorLayer/Editor")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		editor.inspector.on_selected(self, "light")

func on_editor_select():
	$Sprite2D.modulate = Color.RED
	$PointLight2D.shadow_item_cull_mask = 15 #1, 2, 3, 4

func on_editor_deselect():
	$Sprite2D.modulate = Color(1,1,1)
	$PointLight2D.shadow_item_cull_mask = 14 #2, 3, 4

func editor_enter():
	input_pickable = true
	$Sprite2D.visible = true

func editor_exit():
	input_pickable = false
	$Sprite2D.visible = false
