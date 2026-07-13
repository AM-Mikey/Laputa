extends MarginContainer

@onready var main = get_parent()

var buttons = []

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

var disabled := false:
	set(val):
		for section in $Handles.get_children():
			for button in section.get_children():
				button.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE if val else Control.MouseFilter.MOUSE_FILTER_STOP
		var rect_highlight_color = main.editor_color
		if (val):
			rect_highlight_color = Color.GRAY
			rect_highlight_color.a = 0.3
		$ColorRect.color = rect_highlight_color
		$Label.add_theme_color_override("font_color", Color.GRAY if val else Color.WHITE)
		disabled = val


func _ready() -> void:
	for section in $Handles.get_children():
		for button in section.get_children():
			if !(button.button_down.is_connected(on_handle)):
				button.connect("button_down", Callable(self, "on_handle").bind(button))
			buttons.append(button)

func _input(event: InputEvent):
	if !main.w.has_node("EditorLayer/Editor"): return
	var editor = main.w.get_node("EditorLayer/Editor")
	if editor.active_tool == "tile": return

	if event.is_action_released("editor_rmb") && state != "idle":
		var inspector = main.w.get_node("EditorLayer/Editor").inspector
		inspector.on_selected(main, "vu_rect")
		state = "idle"
		editor.active_tool = editor.pre_grab_tool
		editor.subtool = editor.pre_grab_subtool
		return

	if event is InputEventMouseMotion and state != "idle": #dragging or resizing
		var snap := 0.0
		match main.snap_mode:
			main.ToolRectSnapMode.NONE:
				snap = 0.0
			main.ToolRectSnapMode.TO_HALF_GRID:
				snap = 8.0
			main.ToolRectSnapMode.TO_GRID:
				snap = 16.0

		var x = get_global_mouse_position().x + drag_offset.x
		var y = get_global_mouse_position().y + drag_offset.y

		if (snap != 0.0):
			x = snapped(x, snap)
			y = snapped(y, snap)

		var parent_x = main.global_position.x
		var parent_y = main.global_position.y

		match state:
			"drag":
				global_position = Vector2(x, y)
			"resize":
				match active_handle.name:
					"TopLeft":
						offset_top = y - parent_y
						offset_left = x - parent_x
					"TopRight":
						offset_top = y - parent_y
						offset_right = x - parent_x
					"BottomLeft":
						offset_bottom = y - parent_y
						offset_left = x - parent_x
					"BottomRight":
						offset_bottom = y - parent_y
						offset_right = x - parent_x
					"Top":
						offset_top = y - parent_y
					"Bottom":
						offset_bottom = y - parent_y
					"Left":
						offset_left = x - parent_x
					"Right":
						offset_right = x - parent_x

		main.value = Rect2(position, size)

func on_handle(handle):
	var editor = main.w.get_node("EditorLayer/Editor")
	if editor.active_tool == "tile": return

	if handle.name != "Mid":
		state = "resize"
		#editor.pre_grab_tool = editor.active_tool
		#editor.pre_grab_subtool = editor.subtool
		#editor.set_tool("entity", "triggerresize")
		active_handle = handle
		drag_offset = handle.global_position - get_global_mouse_position()
	else:
		state = "drag"
		#editor.pre_grab_tool = editor.active_tool
		#editor.pre_grab_subtool = editor.subtool
		#editor.set_tool("entity", "triggergrab")
		drag_offset = global_position - get_global_mouse_position()

	var inspector = main.w.get_node("EditorLayer/Editor").inspector
	inspector.on_selected(main, "vu_rect")
