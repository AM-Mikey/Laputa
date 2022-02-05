extends EditorProperty

const controlScene = preload("res://addons/frontrider.tiledtools/editor/inspector/TiledmapInspectorView.tscn")
const PropertyInspectorType = preload("res://addons/frontrider.tiledtools/editor/inspector/TiledmapInspectorView.gd")

# The main control for editing the property.
var property_control = controlScene.instance() as PropertyInspectorType
var config_manager
signal update(data)

func _init():
	property_control.config_manager = config_manager
	# Add the control as a direct child of EditorProperty node.
	add_child(property_control)
	# Make sure the control is able to retain the focus.
	add_focusable(property_control)
	
	property_control.connect("update",self,"_update_proprty")
	connect("update",property_control,"update_data")

func _update_proprty(data):
	emit_changed(get_edited_property(), data)
	pass

func update_property():
	var new_value = get_edited_object()[get_edited_property()]
	emit_signal("update",new_value)
	pass

func get_tooltip_text():
	return """
	Select a map exported from Tiled. Must be in the json format.
	"""
	pass
