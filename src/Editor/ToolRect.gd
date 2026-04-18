extends Node2D

enum ToolRectSnapMode {NONE, TO_HALF_GRID, TO_GRID, CUSTOM}

@export var tag_name: String = "":
	set(val):
		$Rect/TagName.text = tag_name
		tag_name = val
@export var snap_mode: ToolRectSnapMode = ToolRectSnapMode.TO_GRID
@export var editor_color: Color = Color(0.85, 0.65, 0.12, 1.0):
	set(val):
		$Rect/ColorRect.color = val
		editor_color = val

var allow_spawn := true
var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

var disabled := false:
	set(val):
		for section in $Rect/Handles.get_children():
			for button in section.get_children():
				button.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE if val else Control.MouseFilter.MOUSE_FILTER_STOP
		var rect_highlight_color = editor_color
		if (val):
			rect_highlight_color = Color.GRAY
			rect_highlight_color.a = 0.3
		$Rect/ColorRect.color = rect_highlight_color
		$Rect/TagName.add_theme_color_override("font_color", Color.GRAY if val else Color.WHITE)
		disabled = val

## In global transform
@export var value: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO):
	set(val):
		value = val
		grid_value = Rect2i(floor(val.position / 16.0), floor(val.size / 16.0))
		update_visual()

@export var grid_value: Rect2i = Rect2i(Vector2i.ZERO, Vector2i.ZERO)

@onready var world = get_tree().get_root().get_node("World")

var buttons = []

func _ready():
	if world.el.get_child_count() == 0: #not in editor
		visible = false

	for section in $Rect/Handles.get_children():
		for button in section.get_children():
			if !(button.button_down.is_connected(on_handle)):
				button.connect("button_down", Callable(self, "on_handle").bind(button))
			buttons.append(button)

	tag_name = tag_name
	editor_color = editor_color
	disabled = false
	if (value == Rect2(Vector2.ZERO, Vector2.ZERO)):
		value = Rect2(get_parent().global_position, Vector2(16, 16))
	else:
		value = value

func update_visual():
	if !(is_inside_tree()):
		return

	$Rect.global_position = value.position
	$Rect.size = value.size

func _input(event: InputEvent):
	if event.is_action_pressed("editor_rmb") and Rect2($Rect.global_position, $Rect.size).has_point(get_global_mouse_position()):
		state = "idle"
		disabled = !disabled
		return
	if event.is_action_released("editor_lmb"):
		state = "idle"
		return
	if event is InputEventMouseMotion and state != "idle": #dragging or resizing
		var snap := 0
		match snap_mode:
			ToolRectSnapMode.NONE:
				snap = 0
			ToolRectSnapMode.TO_HALF_GRID:
				snap = 8
			ToolRectSnapMode.TO_GRID:
				snap = 16

		var x = get_global_mouse_position().x + drag_offset.x
		var y = get_global_mouse_position().y + drag_offset.y
		if (snap != 0.0):
			x = snapped(x, snap)
			y = snapped(y, snap)

		var parent_x = global_position.x
		var parent_y = global_position.y

		#print(x, " ", y, " | ", parent_x, " ", parent_y)

		match state:
			"drag":
				#var tile_map = world.current_level.get_node("TileMap")
				global_position = Vector2(x, y)
			"resize":
				match active_handle.name:
					"TopLeft":
						$Rect.offset_top = y - parent_y
						$Rect.offset_left = x - parent_x
					"TopRight":
						$Rect.offset_top = y - parent_y
						$Rect.offset_right = x - parent_x
					"BottomLeft":
						$Rect.offset_bottom = y - parent_y
						$Rect.offset_left = x - parent_x
					"BottomRight":
						$Rect.offset_bottom = y - parent_y
						$Rect.offset_right = x - parent_x
					"Top":
						$Rect.offset_top = y - parent_y
					"Bottom":
						$Rect.offset_bottom = y - parent_y
					"Left":
						$Rect.offset_left = x - parent_x
					"Right":
						$Rect.offset_right = x - parent_x

		value = Rect2($Rect.global_position, $Rect.size)

### SIGNALS

func on_editor_select(): #when
	modulate = Color(1,0,0,.75)

func on_editor_deselect():
	modulate = Color(1,1,1,.75)


func on_handle(handle):
	if handle.name != "Mid":
		state = "resize"
		active_handle = handle
		drag_offset = handle.global_position - get_global_mouse_position()
	else:
		state = "drag"
		drag_offset = global_position - get_global_mouse_position()
	#emit_signal("selected", self, "tool_rect")
#
	#var inspector = world.get_node("EditorLayer/Editor").inspector
	#inspector.on_selected(self, "tool_rect")
