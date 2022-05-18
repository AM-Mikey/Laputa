tool
extends MarginContainer

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO


export var header_size = 0 setget on_header_size_changed
export var bar_size = 12 setget on_bar_size_changed


func _ready():
	for h in $Handles/Top.get_children():
			h.connect("button_down", self, "on_handle", [h])
	for h in $Handles/Mid.get_children():
			h.connect("button_down", self, "on_handle", [h])
	for h in $Handles/Bottom.get_children():
			h.connect("button_down", self, "on_handle", [h])

func _input(event):
	if event.is_action_released("editor_lmb"):
		state = "idle"
		return
	
	if event is InputEventMouseMotion:
		if state == "drag":
				rect_position = get_global_mouse_position() + drag_offset
		
		if state == "resize":
			var x = get_global_mouse_position().x + drag_offset.x
			var y = get_global_mouse_position().y + drag_offset.y
			
			match active_handle.name:
				"TopLeft":
					margin_top = y
					margin_left = x
				"TopRight":
					margin_top = y
					margin_right = x + 16
				"BottomLeft":
					margin_bottom = y + 16
					margin_left = x
				"BottomRight":
					margin_bottom = y + 16
					margin_right = x + 16
				"Top":
					margin_top = y
				"Bottom":
					margin_bottom = y + 16
				"Left":
					margin_left = x
				"Right":
					margin_right = x + 16

###SIGNALS

func on_header_size_changed(new):
	header_size = new
	$Handles/Header.rect_min_size.y = new
	$Handles/Header/ReferenceRect.rect_size = $Handles/Header.rect_size

func on_bar_size_changed(new):
	bar_size = new
	$Handles/Mid/Bar.rect_min_size.y = new
	$Handles/Mid/Bar/ReferenceRect.rect_size = $Handles/Mid/Bar.rect_size



func on_handle(handle):
	if handle.name != "Bar":
		print("handle grabbed")
		state = "resize"
		active_handle = handle
		drag_offset =  handle.rect_global_position - get_global_mouse_position()
	else:
		state = "drag"
		drag_offset =  rect_global_position - get_global_mouse_position()
