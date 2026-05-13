extends Node2D

enum ToolRectSnapMode {NONE, TO_HALF_GRID, TO_GRID}

@export var tag_name: String = "":
	set(val):
		$Rect/Label.text = tag_name
		tag_name = val
@export var snap_mode: ToolRectSnapMode = ToolRectSnapMode.TO_HALF_GRID
@export var editor_color: Color = Color(0.85, 0.65, 0.12, 1.0):
	set(val):
		$Rect/ColorRect.color = val
		editor_color = val

## In global transform
@export var value: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO):
	set(val):
		value = val
		grid_value = Rect2i(floor(val.position / 16.0), floor(val.size / 16.0))
		update_visual()

@export var grid_value: Rect2i = Rect2i(Vector2i.ZERO, Vector2i.ZERO)

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	if w.el.get_child_count() == 0: #not in editor
		visible = false

	tag_name = tag_name
	editor_color = editor_color

	if (value == Rect2(Vector2.ZERO, Vector2.ZERO)):
		value = Rect2(get_parent().global_position, Vector2(16, 16))
	else:
		value = value

func update_visual():
	if !(is_inside_tree()):
		return

	$Rect.global_position = value.position
	$Rect.size = value.size

### SIGNALS
func on_editor_select(): #when
	modulate = Color(1,0,0,.75)
	%Mid.disabled = false

func on_editor_deselect():
	modulate = Color(1,1,1,.75)
	%Mid.disabled = true
