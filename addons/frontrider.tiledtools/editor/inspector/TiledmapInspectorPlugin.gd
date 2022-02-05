extends EditorInspectorPlugin

const TiledMapType = preload("res://addons/frontrider.tiledtools/map_tools/TilemapLoader.gd")
var TiledmapProperty = preload("res://addons/frontrider.tiledtools/editor/inspector/TiledmapProperty.gd")

var config_manager
func can_handle(object):
	return object is TiledMapType


func parse_property(object, type, path, hint, hint_text, usage):
	if(not object is TiledMapType):
		return false
	# We handle properties of type integer.
	if type == TYPE_STRING:
		#print(path)
		# Create an instance of the custom property editor and register
		# it to a specific property path.
		var prop = TiledmapProperty.new()

		prop.config_manager = config_manager
		add_property_editor(path, prop)
		# Inform the editor to remove the default property editor for
		# this property type.
		return true
	else:
		return false
