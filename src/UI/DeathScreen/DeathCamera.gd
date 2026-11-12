extends Camera2D

var setup_done = false

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = f.pc()
@onready var previous_camera_pos = pc.get_node("PlayerCamera").get_screen_center_position()

func _ready():
	make_current()
	global_position = previous_camera_pos
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	await get_tree().process_frame
	await get_tree().process_frame
	position_smoothing_enabled = true
	setup_done = true

func _process(_delta: float):
	if setup_done:
		global_position = pc.global_position

func on_limit_camera(left, right, top, bottom):
	var window_width = get_window().get_size().x
	var window_height = get_window().get_size().y

	if  window_width > (right - left) * vs.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = ((get_window().get_size().x / vs.resolution_scale) - (right - left))/2
		limit_left = left - extra_margin
		limit_right = right + extra_margin
	else:
		limit_left = left
		limit_right = right

	if window_height > (bottom - top) * vs.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (get_window().get_size().y - (bottom - top))/2
		limit_top = top - extra_margin
		limit_bottom = bottom  + extra_margin
	else:
		limit_top = top
		limit_bottom = bottom



func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
