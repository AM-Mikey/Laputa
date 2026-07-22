extends Node2D

enum ToolRectSnapMode {NONE, TO_HALF_GRID, TO_GRID}

@export var tag_name: String = "":
	set(val):
		$Rect/Label.text = tag_name
		tag_name = val
@export var snap_mode: ToolRectSnapMode = ToolRectSnapMode.TO_HALF_GRID
@export var editor_color: Color = Color(0.85, 0.65, 0.12, 1.0):
	set(val):
		$Rect/Panel.modulate = val
		editor_color = val

signal value_changed(what, old_val, new_val)
## In local transform
@export var value: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO):
	set(val):
		var old_val = value
		value = val
		update_visual()
		if old_val != value:
			value_changed.emit(self, old_val, value)

@onready var w = get_tree().get_root().get_node("World")


func _ready():
	if w.el.get_child_count() == 0: #not in editor
		visible = false

	tag_name = tag_name
	editor_color = editor_color

	if (value == Rect2(Vector2.ZERO, Vector2.ZERO)):
		value = Rect2(Vector2.ZERO, Vector2(16, 16))
	else:
		value = value

func update_visual():
	if !(is_inside_tree()):
		return

	$Rect.position = value.position
	$Rect.size = value.size

### GETTER
func get_global_value() -> Rect2:
	return Rect2(get_parent().global_position + value.position, value.size)

func get_grid_value() -> Rect2i:
	return Rect2i(floor(value.position / 16.0), floor(value.size / 16.0))

func get_global_grid_value() -> Rect2i:
	return Rect2i(floor(get_parent().global_position + value.position / 16.0), floor(value.size / 16.0))

### SIGNALS

func on_editor_select():
	modulate = Color(1,0,0,.75)
	%Mid.disabled = false

func on_editor_deselect():
	modulate = Color(1,1,1,.75)
	%Mid.disabled = true
