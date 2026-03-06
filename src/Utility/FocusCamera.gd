extends Camera2D

var horizontal_focus = Vector2.LEFT #TODO:is this outdated now that we can control using the player camera
var homing_camera = false
var panning_up = false
var panning_down = false

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = f.pc()

func _ready():
	global_position = pc.global_position
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


func on_limit_camera(left, right, top, bottom):
	var window_width = get_window().get_size().x
	var window_height = get_window().get_size().y

	if get_window().get_size().x > (right - left) * w.resolution_scale:
		print("WARNING: window width larger than camera limit")
		var extra_margin = ((get_window().get_size().x / w.resolution_scale) - (right - left))/2

		limit_left = left - extra_margin
		limit_right = right + extra_margin




	else:
		limit_left = left
		limit_right = right

	if get_window().get_size().y > (bottom - top) * w.resolution_scale:
		print("WARNING: window height larger than camera limit")
		var extra_margin = (get_window().get_size().y - (bottom - top))/2
		limit_top = top - extra_margin
		limit_bottom = bottom  + extra_margin


	else:
		limit_top = top
		limit_bottom = bottom



### SIGNALS ###

func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
