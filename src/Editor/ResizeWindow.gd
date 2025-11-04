@tool
extends MarginContainer

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO
var cached_cursor: String

@export var header_size = 0: set = on_header_size_changed
@export var bar_size = 12: set = on_bar_size_changed


func _ready():
	for h in $Handles/Top.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
	for h in $Handles/Mid.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
	for h in $Handles/Bottom.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))

func _input(event):
	if event.is_action_released("editor_lmb"):
		state = "idle"
		$Handles/Mid/Bar.mouse_default_cursor_shape = CURSOR_MOVE
		return

	if event is InputEventMouseMotion:
		match state:
			"drag":
				$Handles/Mid/Bar.mouse_default_cursor_shape = CURSOR_DRAG
				position = Vector2( \
				get_global_mouse_position().x + drag_offset.x, \
				get_global_mouse_position().y + drag_offset.y - (bar_size * 2))

			"resize":
				var x = get_global_mouse_position().x + drag_offset.x
				var y = get_global_mouse_position().y + drag_offset.y

				match active_handle.name:
					"TopLeft":
						offset_top = y - header_size - (bar_size * 2) #idk why the bar size
						offset_left = x
					"TopRight":
						offset_top = y - header_size - (bar_size * 2)
						offset_right = x + 4 #4 because of the size of the buttons
					"BottomLeft":
						offset_bottom = y + 4 - (bar_size * 2)
						offset_left = x
					"BottomRight":
						offset_bottom = y + 4 - (bar_size * 2)
						offset_right = x + 4
					"Top":
						offset_top = y - header_size - (bar_size * 2)
					"Bottom":
						offset_bottom = y + 4 - (bar_size * 2)
					"Left":
						offset_left = x
					"Right":
						offset_right = x + 4

###SIGNALS

func on_header_size_changed(new):
	header_size = new
	$Handles/Header.custom_minimum_size.y = new
	$Handles/Header/ReferenceRect.size = $Handles/Header.size

func on_bar_size_changed(new):
	bar_size = new
	$Handles/Mid/Bar.custom_minimum_size.y = new
	$Handles/Mid/Bar/ReferenceRect.size = $Handles/Mid/Bar.size



func on_handle(handle):
	if handle.name != "Bar":
		print("handle grabbed")
		state = "resize"
		active_handle = handle
		drag_offset = handle.global_position - get_global_mouse_position()
	else:
		state = "drag"
		drag_offset = global_position - get_global_mouse_position()
