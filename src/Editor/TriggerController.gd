extends MarginContainer

signal selected(node, type)

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO

@onready var world = get_tree().get_root().get_node("World")
@onready var editor = world.get_node("EditorLayer/Editor")

var buttons = []

func _ready():
	for h in $Handles/Top.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
			buttons.append(h)
	for h in $Handles/Mid.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
			buttons.append(h)
	for h in $Handles/Bottom.get_children():
			h.connect("button_down", Callable(self, "on_handle").bind(h))
			buttons.append(h)
	connect("selected", Callable(editor.inspector, "on_selected"))


func disable():
	state = "disabled"
	visible = false
func enable():
	state = "enabled"
	visible = true

func _input(event):
	if state == "disabled": return
	
	if event.is_action_released("editor_lmb"):
		state = "idle"
		return
	if event is InputEventMouseMotion and state != "idle": #dragging or resizing
		var x = snapped(get_global_mouse_position().x + drag_offset.x, 16)
		var y = snapped(get_global_mouse_position().y + drag_offset.y, 16)
		
		var parent_x = get_parent().position.x
		var parent_y = get_parent().position.y
		
		match state:
			"drag":
				get_parent().position = Vector2(x, y)
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
				
				var col = get_parent().get_node("CollisionShape2D")
				var parent = get_parent()
				var new_shape = RectangleShape2D.new()
				new_shape.size = size * 0.5
				get_parent().get_node("CollisionShape2D").shape = new_shape
				get_parent().get_node("CollisionShape2D").position = position + new_shape.size
				
				get_parent().visual.update()


### SIGNALS 

func on_handle(handle):
	if state == "disabled": return
	
	if handle.name != "Mid":
		#print("handle grabbed")
		state = "resize"
		active_handle = handle
		drag_offset = handle.global_position - get_global_mouse_position()
	else:
		state = "drag"
		drag_offset = get_parent().position - get_global_mouse_position()
	emit_signal("selected", get_parent(), "trigger")


func on_editor_select():
	modulate = Color.RED

func on_editor_deselect():
	modulate = Color(1,1,1)
