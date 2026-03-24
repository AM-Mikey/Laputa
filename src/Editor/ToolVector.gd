extends Area2D

signal selected(tool_vector, type)

const ARROW_LENGTH := 16.0
const HANDLE_RADIUS := 4.0

@export var tag_name: String
@export var index: int = 0
@export var direction: Vector2 = Vector2.RIGHT:
	set(val):
		direction = _snap_dir_45(val)
		_update_arrow_visuals()
@export var movement_locked: bool = false:
	set(val):
		movement_locked = val
		_update_collision_visibility(val)


var _dragging_tip := false

@onready var w = get_tree().get_root().get_node("World")


func _ready():
	if movement_locked:
		$CollisionShape2D.visible = false
	visible = w.debug_visible
	direction = _snap_dir_45(direction)
	_update_arrow_visuals()


func _unhandled_input(event):
	if !_dragging_tip:
		return

	if event is InputEventMouseMotion:
		var local_mouse = to_local(get_global_mouse_position())
		direction = _snap_dir_45(local_mouse)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and !event.pressed:
		_dragging_tip = false
		get_viewport().set_input_as_handled()


func _on_tip_handle_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_dragging_tip = true
		get_viewport().set_input_as_handled()


func _snap_dir_45(vec: Vector2) -> Vector2:
	if vec == Vector2.ZERO:
		return Vector2.RIGHT
	var snapped_angle = snappedf(vec.angle(), PI / 4.0)
	return Vector2.RIGHT.rotated(snapped_angle).normalized()


func _update_arrow_visuals():
	if !is_inside_tree():
		return
	var tip_pos = direction.normalized() * ARROW_LENGTH
	$Line2D.rotation = direction.angle()
	$ArrowHead.rotation = direction.angle()
	$TipHandle.position = tip_pos

func _update_collision_visibility(val):
	if !is_inside_tree():
		return
	$CollisionShape2D.visible = val

func on_editor_select():
	$Line2D.default_color = Color.RED
	$ArrowHead.modulate = Color.RED


func on_editor_deselect():
	$Line2D.default_color = Color(0.85, 0.65, 0.12, 1.0)
	$ArrowHead.modulate = Color(0.85, 0.65, 0.12, 1.0)


func on_pressed():
	emit_signal("selected", self, "tool_vector")


func _input_event(_viewport, event, _shape_idx):
	var editor = w.get_node("EditorLayer/Editor")
	if !movement_locked:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			editor.inspector.on_selected(self, "tool_vector")
