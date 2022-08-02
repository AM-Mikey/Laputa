extends Camera2D

onready var w = get_tree().get_root().get_node("World")

var current_zoom: int
var zooms = [
	0.125,
	0.167,
	0.2,
	0.25,
	0.333,
	0.5,
	0.666,
	1.0,
	1.333,
	2.0,
	3.0,
	4.0,
]
var mmb_held = false

func _ready():
	add_to_group("Cameras")
	
	zoom = Vector2(1 / w.resolution_scale, 1 / w.resolution_scale)
	current_zoom = zooms.find(1 / w.resolution_scale)
	global_position = w.get_node("Juniper/PlayerCamera").global_position 
	
func _input(event): #_unhandled
	#print("unhandled input")
	if event.is_action_pressed("editor_scroll_down"):
		if current_zoom < zooms.size() - 1:
			var old_zoom = current_zoom
			current_zoom += 1
			zoom = Vector2(zooms[current_zoom], zooms[current_zoom])
			#camera_to_mouse()
			global_position += (-0.5 * get_viewport().size + get_viewport().get_mouse_position()) * (zooms[old_zoom] - zooms[current_zoom])

	if event.is_action_pressed("editor_scroll_up"):
		if current_zoom > 0:
			var old_zoom = current_zoom
			current_zoom -= 1
			zoom = Vector2(zooms[current_zoom], zooms[current_zoom])
			#camera_to_mouse()
			global_position += (-0.5 * get_viewport().size + get_viewport().get_mouse_position()) * (zooms[old_zoom] - zooms[current_zoom])
			

	if event.is_action_pressed("editor_mmb"):
		mmb_held = true
	if event.is_action_released("editor_mmb"):
		mmb_held = false

	if event is InputEventMouseMotion and mmb_held:
		position -= event.relative * zoom.x

#func camera_to_mouse():
#	var old_center_pos = get_camera_screen_center() # get_viewport().get_size() /2#
#	var mouse_pos = w.get_global_mouse_position()#get_viewport().get_mouse_position()
#
#	print("old", old_center_pos)
#	print("mouse", mouse_pos)
#
#	#global_position -= (old_center_pos - mouse_pos) / 2
#
#	#global_position += (mouse_pos - old_center_pos) /2 #* 1/zoom 
#	yield(get_tree(), "idle_frame")
#
#
#
#
#	print("new", get_camera_screen_center())
