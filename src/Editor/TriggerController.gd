extends MarginContainer

signal selected(node, type)

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

onready var world = get_tree().get_root().get_node("World")
onready var editor = world.get_node("EditorLayer/Editor")


func _ready():
	for h in $Handles/Top.get_children():
			h.connect("button_down", self, "on_handle", [h])
	for h in $Handles/Mid.get_children():
			h.connect("button_down", self, "on_handle", [h])
	for h in $Handles/Bottom.get_children():
			h.connect("button_down", self, "on_handle", [h])
	connect("selected", editor.inspector, "on_selected")

func _input(event):
	if event.is_action_released("editor_lmb"):
		state = "idle"
		return
	if event is InputEventMouseMotion and state != "idle": #dragging or resizing
		var x = stepify(get_global_mouse_position().x + drag_offset.x, 16)
		var y = stepify(get_global_mouse_position().y + drag_offset.y, 16)
		match state:
			"drag":
				rect_position = Vector2(x, y)
			"resize":
				
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
						margin_right = x #+ 4'
	
	else:
		set_process_unhandled_input(true)

### SIGNALS 

func on_handle(handle):
	if handle.name != "Mid":
		#print("handle grabbed")
		state = "resize"
		active_handle = handle
		drag_offset = handle.rect_global_position - get_global_mouse_position()
	else:
		state = "drag"
		drag_offset = rect_global_position - get_global_mouse_position()
	emit_signal("selected", self, "triggercontroller")


func on_editor_select():
	modulate = Color.red

func on_editor_deselect():
	modulate = Color(1,1,1)
