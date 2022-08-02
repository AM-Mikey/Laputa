tool
extends MarginContainer

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO



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
		match state:
			"drag":
				rect_position = get_global_mouse_position() + drag_offset
			"resize":
				var x = stepify(get_global_mouse_position().x + drag_offset.x, 16)
				var y = stepify(get_global_mouse_position().y + drag_offset.y, 16)
				
				match active_handle.name:
					"TopLeft":
						margin_top = y
						margin_left = x
					"TopRight":
						margin_top = y
						margin_right = x #+ 4 #no idea why this is 4
					"BottomLeft":
						margin_bottom = y #+ 4
						margin_left = x
					"BottomRight":
						margin_bottom = y #+ 4
						margin_right = x #+ 4
					"Top":
						margin_top = y
					"Bottom":
						margin_bottom = y #+ 4
					"Left":
						margin_left = x
					"Right":
						margin_right = x #+ 4
