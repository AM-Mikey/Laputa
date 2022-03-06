extends Object


var tileset_path = "res://assets/tileset_folder"
var tileset_path_properties_name = "tiled_tools/tileset_folder"

var tiled_path = "tiled"
var tiled_path_properties_name = "tiled_tools/tiled_path"


func init_config():
	create_directory_setting(tileset_path_properties_name,tileset_path)
	create_string_setting(tiled_path_properties_name,tiled_path,"""
	Path to the Tiled executeable.
	""")
	pass
	
func get_tileset_folder():
	return ProjectSettings.get_setting(tileset_path_properties_name)
	pass

func get_tiled():
	return ProjectSettings.get_setting(tiled_path_properties_name)
	pass
func create_directory_setting(name,default_value):
	if(!ProjectSettings.has_setting(name)):
		ProjectSettings.set_setting(name,default_value)
		print("creating setting: "+name)
		
		var property_info = {
			"name": name,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_DIR
		}
		ProjectSettings.add_property_info(property_info)
	return ProjectSettings.get_setting(name)

func create_int_setting(name,default_value):
	if(!ProjectSettings.has_setting(name)):
		ProjectSettings.set_setting(name,default_value)
		print("creating setting: "+name)
		
		var property_info = {
			"name": name,
			"type": TYPE_INT,
		}
		ProjectSettings.add_property_info(property_info)
	return ProjectSettings.get_setting(name)

func create_string_setting(name,default_value,hint_string):
	if(!ProjectSettings.has_setting(name)):
		ProjectSettings.set_setting(name,default_value)
		print("creating setting: "+name)
		
		var property_info = {
			"name": name,
			"type": TYPE_STRING,
			"hint_string":hint_string
		}
		ProjectSettings.add_property_info(property_info)
	return ProjectSettings.get_setting(name)
