extends MarginContainer

onready var world = get_tree().get_root().get_node("World")
onready var level_limiter = world.current_level.get_node("LevelLimiter")

var state = "idle"
var active_handle = null
var drag_offset = Vector2.ZERO


func _ready():
	rect_position = level_limiter.rect_position - Vector2(8,8)
	rect_size = level_limiter.rect_size + Vector2(16,16)
	
	for c in get_children():
		if c is TextureButton:
			c.connect("button_down", self, "on_handle", [c])


func on_handle(handle):
	state = "resize"
	active_handle = handle
	drag_offset =  handle.rect_global_position - get_global_mouse_position()



func _input(event):
	if state == "resize":
		if event is InputEventMouseMotion:
			var x = stepify(get_global_mouse_position().x + drag_offset.x, 16)
			var y = stepify(get_global_mouse_position().y + drag_offset.y, 16)
			
			match active_handle.name:
				"TopLeft":
					margin_top = y
					margin_left = x
				"TopRight":
					margin_top = y
					margin_right = x
				"BottomLeft":
					margin_bottom = y
					margin_left = x
				"BottomRight":
					margin_bottom = y
					margin_right = x
				"Top":
					margin_top = y
				"Bottom":
					margin_bottom = y
				"Left":
					margin_left = x
				"Right":
					margin_right = x
			
			level_limiter.rect_global_position = $MarginContainer/LevelRect.rect_global_position
			level_limiter.rect_size = $MarginContainer/LevelRect.rect_size
			level_limiter.on_viewport_size_changed()
		
		if event.is_action_released("editor_lmb"):
			state = "idle"
