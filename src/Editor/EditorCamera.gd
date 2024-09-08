extends Camera2D

@onready var w = get_tree().get_root().get_node("World")

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
]
var mmb_held = false

func _ready():
	add_to_group("Cameras")
	
	zoom = Vector2(w.resolution_scale, w.resolution_scale)
	current_zoom_index = zooms.find(w.resolution_scale)
	global_position = w.get_node("Juniper/PlayerCamera").global_position 
	
func _input(event):
	if event.is_action_pressed("editor_mmb"):
		mmb_held = true
	if event.is_action_released("editor_mmb"):
		mmb_held = false

	if event is InputEventMouseMotion and mmb_held:
		position -= event.relative * 1/zoom.x

func _unhandled_input(event):
	if event.is_action_pressed("editor_scroll_up"):
		if current_zoom_index < zooms.size() - 1:
			var old_zoom_index = current_zoom_index
			current_zoom_index += 1
			zoom = Vector2(zooms[current_zoom_index], zooms[current_zoom_index])
			global_position += (-0.5 * get_viewport().size + get_viewport().get_mouse_position()) * ((1/zooms[old_zoom_index]) - (1/zooms[current_zoom_index]))

	if event.is_action_pressed("editor_scroll_down"):
		if current_zoom_index > 0:
			var old_zoom_index = current_zoom_index
			current_zoom_index -= 1
			zoom = Vector2(zooms[current_zoom_index], zooms[current_zoom_index])
			global_position += (-0.5 * get_viewport().size + get_viewport().get_mouse_position()) * ((1/zooms[old_zoom_index]) - (1/zooms[current_zoom_index]))
