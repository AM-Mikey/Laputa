extends Node

signal scale_changed(resolution_scale)

var resolution_scale := 4.0
var menu_resolution_scale := 4.0
var debug_resolution_scale := 1.0
var inventory_resolution_scale := 4.0


func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "_viewport_size_changed"))
	_viewport_size_changed()

func _viewport_size_changed():
	var camera = get_viewport().get_camera_2d()
	if camera:
		if camera.is_in_group("PlayerCameras"):
			camera.position_smoothing_enabled = false
	#basic
	var viewport_size = get_tree().get_root().size
	var tiles_visible_y = 15.0
	var urs = viewport_size.y / (16.0 * tiles_visible_y)
	resolution_scale = get_res_scale_from_urs(urs)
	#menu
	var tiles_visible_x = 30.0
	var menu_urs = viewport_size.x / (16.0 * tiles_visible_x)
	menu_resolution_scale = get_res_scale_from_urs(menu_urs)
	#inventory
	var inventory_size = Vector2(288, 232)
	var inventory_urs_x = viewport_size.x / inventory_size.x
	var inventory_urs_y = viewport_size.y / inventory_size.y
	var inventory_urs = min(inventory_urs_x, inventory_urs_y)
	inventory_resolution_scale = get_res_scale_from_urs(inventory_urs, true)

	emit_signal("scale_changed", resolution_scale)
	await get_tree().process_frame
	await get_tree().process_frame
	if camera:
		if camera.is_in_group("PlayerCameras"):
			camera.position_smoothing_enabled = true



### HELPERS ###

func get_res_scale_from_urs(urs, always_round_down = false) -> float:
	var out = urs
	if always_round_down:
		out = floor(out) #round down
	elif out - floor(out) == 0.5:
		out = floori(out) #round 0.5 down
	else:
		out = roundi(out) #else round normally
	out = max(out, 1)
	return out
