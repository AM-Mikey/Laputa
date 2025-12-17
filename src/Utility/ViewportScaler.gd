extends Node

signal scale_changed(resolution_scale)

var resolution_scale:= 4.0
var menu_resolution_scale:= 4.0


func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "_viewport_size_changed"))
	_viewport_size_changed()

func _viewport_size_changed():
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.position_smoothing_enabled = false

	var viewport_size = get_tree().get_root().size
	var tiles_visible_y = 15.0
	var urs = viewport_size.y / (16.0 * tiles_visible_y)
	if urs - floor(urs) == 0.5:
		resolution_scale = floori(urs) #round 0.5 down
	else:
		resolution_scale = roundi(urs) #else round normally
	resolution_scale = max(resolution_scale, 1)


	var tiles_visible_x = 30.0
	var menu_urs = viewport_size.x / (16.0 * tiles_visible_x)
	if menu_urs - floor(menu_urs) == 0.5:
		menu_resolution_scale = floori(menu_urs) #round 0.5 down
	else:
		menu_resolution_scale = roundi(menu_urs) #else round normally
	menu_resolution_scale = max(menu_resolution_scale, 1)

	emit_signal("scale_changed", resolution_scale)
	await get_tree().process_frame
	if camera:
		camera.position_smoothing_enabled = true
