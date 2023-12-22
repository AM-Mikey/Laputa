@tool
extends MarginContainer

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO


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
		return
	
	if event is InputEventMouseMotion:
		match state:
			"drag":
				position = get_global_mouse_position() + drag_offset
			"resize":
				var x = get_global_mouse_position().x + drag_offset.x
				var y = get_global_mouse_position().y + drag_offset.y
				
				match active_handle.name:
					"TopLeft":
						offset_top = y - header_size
						offset_left = x
					"TopRight":
						offset_top = y - header_size
						offset_right = x + 4 #no idea why this is 4
					"BottomLeft":
						offset_bottom = y + 4
						offset_left = x
					"BottomRight":
						offset_bottom = y + 4
						offset_right = x + 4
					"Top":
						offset_top = y - header_size
					"Bottom":
						offset_bottom = y + 4
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
