extends MarginContainer

const PROPERTY_BUTTON = preload("res://src/Editor/Button/PropertyButton.tscn")
const LAYER_BUTTON = preload("res://src/Editor/Button/LayerButton.tscn")
const EXPORT = PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE + PropertyUsageFlags.PROPERTY_USAGE_STORAGE + PropertyUsageFlags.PROPERTY_USAGE_EDITOR

@onready var editor = get_parent().get_parent().get_parent()

var active = null
var active_type: String
var active_property: String #only use for referencing file dialog's user


func _physics_process(delta):
	display_tool_labels()

func exit():
	on_deselected()


### SELECTING

func on_selected(selection, selection_type):
	if selection.is_in_group("Previews"): return
	
	if active: #deselect old
		if active.has_method("on_editor_deselect"): active.on_editor_deselect()
	active = selection
	active_type = selection_type
	if active: #select new
		if active.has_method("on_editor_select"): active.on_editor_select()
	display_data()
	
	match active_type:
		"spawn_point":
			editor.set_tool("entity", "noplace")
		#"actor_spawn": this just makes it so we cant place enemies. weird
			#editor.set_tool("entity", "noplace")
		"light":
			editor.set_tool("entity", "noplace")
		_:
			pass

func on_deselected():
	if active:
		if active.has_method("on_editor_deselect"): active.on_editor_deselect()
	active = null
	active_type = ""
	active_property = ""
	clear_data()
	

### DISPLAY DATA

func display_data():
	clear_data()
	$Margin/VBox/Label.text = active.name
	
	match active_type:
		"background":
			var level_rect = active.get_node("Margin/LevelRect")
			var limiter = active.level_limiter
			create_button("texture", limiter.texture.resource_path, "load")
			create_button("layers", limiter.layers, "int")
			create_button("parallax_near", limiter.parallax_near, "float")
			create_button("parallax_far", limiter.parallax_far, "float")
			create_button("focus", limiter.focus, "enum", limiter.Focus.keys())
			create_button("tile_mode", limiter.tile_mode, "enum", limiter.TileMode.keys())
		"actor_spawn":
			for p in active.properties:
				create_button(p, active.properties[p][0], get_property_type(active.properties[p][1]))
		#"enemy": #replaced with actor spawn
			#for p in active.get_property_list():
				#if p["usage"] == EXPORT:
					#create_button(p["name"], active.get(p["name"]), p["type"])
		#"npc":
			#for p in active.get_property_list():
				#if p["usage"] == EXPORT:
					#create_button(p["name"], active.get(p["name"]), p["type"])
		"prop":
			for p in active.get_property_list():
				if p["usage"] == EXPORT:
					create_button(p["name"], active.get(p["name"]), p["type"])
		"trigger":
			for p in active.get_property_list():
				if p["name"] == "level": #a trigger wants to load a level path
					create_button("level", active.get("level"), "load")
				
				elif p["usage"] == EXPORT:
					create_button(p["name"], active.get(p["name"]), p["type"])
		"level":
			create_button("level_name", active.level_name, "string")
			create_button("level_type", active.level_type, "enum", active.LevelType.keys())
			create_button("tile_set", active.tile_set.resource_path, "load")
			create_button("music", active.music, "load")
			create_button("dialog_json", active.dialog_json, "load")
			create_button("conversation", active.conversation, "string")
		"light":
			for p in active.get_property_list():
				if p["usage"] == EXPORT:
					create_button(p["name"], active.get(p["name"]), p["type"])
		"tile_collection":
			var tile_map = active.get_child(0)
			for layer_id in tile_map.get_layers_count():
				create_layer_button(layer_id)

func get_property_type(type_flag) -> String:
	var out = ""
	match type_flag:
		Variant.Type.TYPE_BOOL: out = "bool"
		Variant.Type.TYPE_COLOR: out = "color"
		Variant.Type.TYPE_INT: out = "int"
		Variant.Type.TYPE_FLOAT: out = "float"
		Variant.Type.TYPE_STRING: out = "string"
		Variant.Type.TYPE_VECTOR2: out = "vector2"
	#TODO: add 	"enum" and "load"
	return out



func on_property_selected(property_name):
	active_property = property_name
	match active_type:
		"background":
			match property_name:
				"texture":
					$FileDialog.current_dir = "res://assets/Background/"
					$FileDialog.set_filters(PackedStringArray(["*.png"]))
					$FileDialog.popup()
		
		"level":
			match property_name:
				"tile_set":
					$FileDialog.current_dir = "res://src/Tile/"
					$FileDialog.set_filters(PackedStringArray(["*.tres"]))
					$FileDialog.popup()
				"dialog_json":
					$FileDialog.current_dir = "res://src/Dialog/"
					$FileDialog.set_filters(PackedStringArray(["*.json"]))
					$FileDialog.popup()
				"music":
					$FileDialog.current_dir = "res://assets/Music/"
					$FileDialog.set_filters(PackedStringArray(["*.wav"]))
					$FileDialog.popup()
		"npc":
			match property_name:
				"dialog_json":
					$FileDialog.current_dir = "res://src/Dialog/"
					$FileDialog.set_filters(PackedStringArray(["*.json"]))
					$FileDialog.popup()
		"trigger":
			match property_name:
				"level":
					$FileDialog.current_dir = "res://src/Level/"
					$FileDialog.set_filters(PackedStringArray(["*.tscn"]))
					$FileDialog.popup()



func on_property_changed(property_name, property_value):
	match active_type:
		"background":
			match property_name:
				"offset_left", "offset_top", "offset_right", "offset_bottom":
					pass
				"layers", "parallax_near", "parallax_far", "focus", "tile_mode":
					active.level_limiter.set(property_name, property_value)
					active.level_limiter.setup_layers()
					active.level_limiter.set_focus()
				"texture":
					active.level_limiter.set(property_name, load(property_value))
					active.level_limiter.setup_layers()
					active.level_limiter.set_focus()
		"actor_spawn":
			active.properties[property_name][0] = property_value
			#active.set(properties[property_name][0], property_value/
		"enemy":
			active.set(property_name, property_value)
			
		"level":
			match property_name:
				"tile_set": 
					active.set(property_name, load(property_value))
					editor.on_TileSet_tile_set_loaded(property_value)
					editor.on_TileSet_tile_set_loaded(property_value)
				_:
					active.set(property_name, property_value)
		"light":
			active.set(property_name, property_value)
			active.setup_colors()
		"npc":
			active.set(property_name, property_value)
		"trigger":
			active.set(property_name, property_value)
			active.visual.update()
		_:
			active.set(property_name, property_value)
	display_data() #to reload
	
	editor.log.lprint(str("Changed ", active_type, " ", active.name, "'s ", property_name, " to ", property_value))
	print("Changed ", active_type, " ", active.name, "'s ", property_name, " to ", property_value)



func on_file_selected(path):
	on_property_changed(active_property, path)




### HELPERS

func clear_data():
	$Margin/VBox/Label.text = ""
	for c in $Margin/VBox/Scroll/VBox.get_children():
		c.queue_free()

func create_button(property, value, type = TYPE_NIL, enum_items = []):
	if property == "editor_hidden":
		return
	var button = PROPERTY_BUTTON.instantiate()
	button.property_name = property
	button.property_value = value
	button.property_type = type
	button.enum_items = enum_items
	$Margin/VBox/Scroll/VBox.add_child(button)
	button.connect("property_changed", Callable(self, "on_property_changed"))
	button.connect("property_selected", Callable(self, "on_property_selected"))

func create_layer_button(layer_id):
	var button = LAYER_BUTTON.instantiate()
	button.layer_id = layer_id
	if layer_id == editor.active_tile_map_layer:
		button.active = true
	button.tile_map = editor.tile_map
	$Margin/VBox/Scroll/VBox.add_child(button)
	button.connect("layer_changed", Callable(editor, "on_layer_changed"))

func display_tool_labels():
	$Margin/VBox/HBox/Tool.text = editor.active_tool
	$Margin/VBox/HBox/Subtool.text = editor.subtool
