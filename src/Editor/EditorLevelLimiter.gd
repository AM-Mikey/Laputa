extends MarginContainer

signal selected(background, type)

@onready var world = get_tree().get_root().get_node("World")
@onready var level_limiter = world.current_level.get_node("LevelLimiter")
@onready var editor = world.get_node("EditorLayer/Editor")

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO


func _ready():
	position = level_limiter.position - Vector2(16,16)
	size = level_limiter.size + Vector2(32,32)
	
	for c in get_children():
		if c is TextureButton:
			c.connect("button_down", Callable(self, "on_handle").bind(c))
	
	connect("selected", Callable(editor.inspector, "on_selected"))


func on_handle(handle):
	state = "resize"
	active_handle = handle
	drag_offset =  handle.global_position - get_global_mouse_position()
	emit_signal("selected", self, "background")



func _input(event):
	if state == "resize":
		if event is InputEventMouseMotion:
			var x = snapped(get_global_mouse_position().x + drag_offset.x, 16)
			var y = snapped(get_global_mouse_position().y + drag_offset.y, 16)
			
			match active_handle.name:
				"TopLeft":
					offset_top = y
					offset_left = x
				"TopRight":
					offset_top = y
					offset_right = x
				"BottomLeft":
					offset_bottom = y
					offset_left = x
				"BottomRight":
					offset_bottom = y
					offset_right = x
				"Top":
					offset_top = y
				"Bottom":
					offset_bottom = y
				"Left":
					offset_left = x
				"Right":
					offset_right = x
			
			level_limiter.global_position = $Margin/LevelRect.global_position
			level_limiter.size = $Margin/LevelRect.size
			level_limiter.on_viewport_size_changed()
		
		if event.is_action_released("editor_lmb"):
			state = "idle"

### SIGNALS

func on_editor_select():
	modulate = Color.RED

func on_editor_deselect():
	modulate = Color(1,1,1)
