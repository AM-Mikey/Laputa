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
		
		var parent_x = get_parent().position.x
		var parent_y = get_parent().position.y
		
		match state:
			"drag":
				get_parent().position = Vector2(x, y)
			"resize":
				match active_handle.name:
					"TopLeft":
						margin_top = y - parent_y
						margin_left = x - parent_x
					"TopRight":
						margin_top = y - parent_y
						margin_right = x - parent_x
					"BottomLeft":
						margin_bottom = y - parent_y
						margin_left = x - parent_x
					"BottomRight":
						margin_bottom = y - parent_y
						margin_right = x - parent_x
					"Top":
						margin_top = y - parent_y
					"Bottom":
						margin_bottom = y - parent_y
					"Left":
						margin_left = x - parent_x
					"Right":
						margin_right = x - parent_x
				
				var col = get_parent().get_node("CollisionShape2D")
				var parent = get_parent()
				var new_shape = RectangleShape2D.new()
				new_shape.extents = rect_size * 0.5
				get_parent().get_node("CollisionShape2D").shape = new_shape
				get_parent().get_node("CollisionShape2D").position = rect_position + new_shape.extents
				
				get_parent().visual.update()


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
