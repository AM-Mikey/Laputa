extends MarginContainer

const PROPERTY_BUTTON = preload("res://src/Editor/Button/PropertyButton.tscn")
const LAYER_BUTTON = preload("res://src/Editor/Button/LayerButton.tscn")

onready var editor = get_parent().get_parent()

var active
var active_type: String
var active_property: String #only use for referencing file dialog's user


func _physics_process(delta):
	display_tool_labels()

func exit():
	on_deselected()


### SELECTING

func on_selected(selection, selection_type):
	if selection.is_in_group("Previews"):
		return
	
	if active:
		if active.has_method("on_editor_deselect"):
			active.on_editor_deselect()
	active = selection
	active_type = selection_type
	if active:
		if active.has_method("on_editor_select"):
			active.on_editor_select()
	display_data()
	
	match active_type:
		"spawn_point":
			editor.set_tool("entity", "noplace")
		"light":
			editor.set_tool("entity", "noplace")
		_:
			pass

func on_deselected():
	if active:
		if active.has_method("on_editor_deselect"):
			active.on_editor_deselect()
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
		"enemy":
			#print(enemy.get_property_list())
			for p in active.get_property_list():
				if p["usage"] == 8199: #exported properties
					create_button(p["name"], active.get(p["name"]), p["type"])
		"npc":
			for p in active.get_property_list():
				if p["usage"] == 8199: #exported properties
					create_button(p["name"], active.get(p["name"]), p["type"])
		"prop":
			for p in active.get_property_list():
				if p["usage"] == 8199: #exported properties
					create_button(p["name"], active.get(p["name"]), p["type"])
		"trigger":
			for p in active.get_property_list():
				if p["usage"] == 8199: #exported properties
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
				if p["usage"] == 8199: #exported properties
					create_button(p["name"], active.get(p["name"]), p["type"])
		"tile_collection":
			#create_button("auto_select_layer", true, "bool")
			var layers = []
			for c in active.get_children():
				if c is TileMap:
					layers.append(c)
			
			var id = 0
			for layer in layers:
				create_layer(layer, id)
				id += 1



func on_property_selected(property_name):
	active_property = property_name
	match active_type:
		"background":
			match property_name:
				"texture":
					$FileDialog.current_dir = "res://assets/Background/"
					$FileDialog.set_filters(PoolStringArray(["*.png"]))
					$FileDialog.popup()
		
		"level":
			match property_name:
				"tile_set":
					$FileDialog.current_dir = "res://src/Tile/"
					$FileDialog.set_filters(PoolStringArray(["*.tres"]))
					$FileDialog.popup()
				"dialog_json":
					$FileDialog.current_dir = "res://src/Dialog/"
					$FileDialog.set_filters(PoolStringArray(["*.json"]))
					$FileDialog.popup()
				"music":
					$FileDialog.current_dir = "res://assets/Music/"
					$FileDialog.set_filters(PoolStringArray(["*.wav"]))
					$FileDialog.popup()
		"npc":
			match property_name:
				"dialog_json":
					$FileDialog.current_dir = "res://src/Dialog/"
					$FileDialog.set_filters(PoolStringArray(["*.json"]))
					$FileDialog.popup()



func on_property_changed(property_name, property_value):
	match active_type:
		"background":
			match property_name:
				"margin_left", "margin_top", "margin_right", "margin_bottom":
					pass
				"layers", "parallax_near", "parallax_far", "focus", "tile_mode":
					active.level_limiter.set(property_name, property_value)
					active.level_limiter.setup_layers()
					active.level_limiter.set_focus()
				"texture":
					active.level_limiter.set(property_name, load(property_value))
					active.level_limiter.setup_layers()
					active.level_limiter.set_focus()
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
		_:
			active.set(property_name, property_value)
	display_data() #to reload
	print("Changed " + active_type + " " + active.name + "'s " + property_name + " to " + String(property_value))



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
	var button = PROPERTY_BUTTON.instance()
	button.property_name = property
	button.property_value = value
	button.property_type = type
	button.enum_items = enum_items
	$Margin/VBox/Scroll/VBox.add_child(button)
	button.connect("property_changed", self, "on_property_changed")
	button.connect("property_selected", self, "on_property_selected")

func create_layer(layer, id):
	var button = LAYER_BUTTON.instance()
	button.layer = layer
	if id == 0:
		button.active = true
	$Margin/VBox/Scroll/VBox.add_child(button)
	button.connect("layer_changed", editor, "on_layer_changed")

func display_tool_labels():
	$Margin/VBox/HBox/Tool.text = editor.active_tool
	$Margin/VBox/HBox/Subtool.text = editor.subtool
