extends Camera2D

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = f.pc()

@onready var player_pos = pc.global_position
@onready var camera_pos = pc.get_node("PlayerCamera").get_screen_center_position()

func _ready():
	global_position = camera_pos
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


func focus_player():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", player_pos, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func on_limit_camera(left, right, top, bottom):
	var window_width = get_window().get_size().x
	var window_height = get_window().get_size().y

	if  get_window().get_size().x > (right - left) * vs.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = ((get_window().get_size().x / vs.resolution_scale) - (right - left))/2

		limit_left = left - extra_margin
		limit_right = right + extra_margin


	else:
		limit_left = left
		limit_right = right

	if get_window().get_size().y > (bottom - top) * vs.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (get_window().get_size().y - (bottom - top))/2
		limit_top = top - extra_margin
		limit_bottom = bottom  + extra_margin


	else:
		limit_top = top
		limit_bottom = bottom



func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
