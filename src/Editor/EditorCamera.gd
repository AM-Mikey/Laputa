extends Camera2D

signal camera_zoom_changed()

@onready var w = get_tree().get_root().get_node("World")
@onready var editor = w.get_node("EditorLayer/Editor")

var current_zoom_index: int
var zooms = [
	0.125,
	0.167,
	0.2,
	0.25,
	0.333,
	0.5,
	0.666,
	1.0,
	1.5,
	2.0,
	3.0,
	4.0,
	5.0,
	6.0,
	7.0,
	8.0
]
var mmb_held = false

func _ready():
	zoom = Vector2(vs.resolution_scale, vs.resolution_scale)
	current_zoom_index = zooms.find(float(vs.resolution_scale))
	global_position = w.get_node("Juniper/PlayerCamera").global_position

func _input(event):
	if event.is_action_pressed("editor_mmb"):
		mmb_held = true
	if event.is_action_released("editor_mmb"):
		mmb_held = false

	if event is InputEventMouseMotion and mmb_held:
		position -= event.relative * 1/zoom.x

func _unhandled_input(event):
	if event.is_action_pressed("editor_scroll_up") or event.is_action_pressed("editor_scroll_down"):
		var old_zoom_index = current_zoom_index
		if event.is_action_pressed("editor_scroll_up") and current_zoom_index < zooms.size() - 1:
			current_zoom_index += 1
		if event.is_action_pressed("editor_scroll_down") and current_zoom_index > 0:
			current_zoom_index -= 1

		zoom = Vector2(zooms[current_zoom_index], zooms[current_zoom_index])
		global_position += (-0.5 * get_viewport().size + get_viewport().get_mouse_position()) * ((1/zooms[old_zoom_index]) - (1/zooms[current_zoom_index]))
		emit_signal("camera_zoom_changed")
		editor.log.lprint("Zoomed to %.2fx" % zoom.x)
