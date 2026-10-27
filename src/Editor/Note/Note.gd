extends MarginContainer

@export_multiline var text : String
@export var color := Color.MAGENTA
@export var big_text := true

var buttons = []
var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	if w.el.get_child_count() == 0: #not in editor
		visible = false
	update_text()

	for section in $Handles.get_children():
		for button in section.get_children():
			if !(button.button_down.is_connected(_on_handle)):
				button.connect("button_down", Callable(self, "_on_handle").bind(button))
			buttons.append(button)


func update_text():
	%Label.text = text
	%Label.set("theme_override_colors/default_color", color)
	var font_size := 32 if big_text else 16
	%Label.set("theme_override_font_sizes/normal_font_size", font_size)

func _input(event):
	if !w.has_node("EditorLayer/Editor"): return
	var editor = w.get_node("EditorLayer/Editor")

	if event.is_action_released("editor_rmb") && state != "idle":
		var inspector = w.get_node("EditorLayer/Editor").inspector
		inspector.on_selected(self, "note")
		state = "idle"
		editor.active_tool = editor.pre_grab_tool
		editor.subtool = editor.pre_grab_subtool
		return

	if event is InputEventMouseMotion && state != "idle": #dragging or resizing
		var x = snapped(get_global_mouse_position().x + drag_offset.x, 8)
		var y = snapped(get_global_mouse_position().y + drag_offset.y, 8)
		var parent_x = get_parent().position.x
		var parent_y = get_parent().position.y
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

func on_editor_select():
	modulate = Color.RED

func on_editor_deselect():
	modulate = Color(1,1,1)

func _on_handle(handle):
	var editor = w.get_node("EditorLayer/Editor")
	var inspector = w.get_node("EditorLayer/Editor").inspector
	inspector.on_selected(self, "note")

	if handle.name != "Mid":
		state = "resize"
		editor.pre_grab_tool = editor.active_tool
		editor.pre_grab_subtool = editor.subtool
		editor.set_tool("entity", "noteresize")
		active_handle = handle
		drag_offset = handle.global_position - get_global_mouse_position()
	else:
		state = "drag"
		editor.pre_grab_tool = editor.active_tool
		editor.pre_grab_subtool = editor.subtool
		editor.set_tool("entity", "notegrab")
		drag_offset = global_position - get_global_mouse_position()

#func _on_gui_input(event: InputEvent) -> void:
	#pass # Replace with function body.
