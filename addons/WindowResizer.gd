tool
extends EditorPlugin
func _ready():
	#yield(get_tree(), "idle_frame")
	OS.set_window_maximized(false)
	OS.set_window_position(Vector2(-1290, 0))
	OS.set_window_size(Vector2(1280+1920+2, 1080-50))
