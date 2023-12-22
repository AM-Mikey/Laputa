extends MarginContainer

const PROP_BUTTON = preload("res://src/Editor/Button/PropButton.tscn")

signal prop_changed(prop_path)

var props = {}
var active_prop_path

@onready var editor = get_parent().get_parent().get_parent()

func _ready():
	setup_props()


func setup_props():
	var index = 0
	for p in find_prop_scenes("res://src/Prop/"):
		
		var prop = load(p).instantiate()
		if not prop.editor_hidden:
			props[prop.name] = prop
			
			var prop_button = PROP_BUTTON.instantiate()
			prop_button.prop_path = p
			prop_button.prop_name = prop.name
			prop_button.connect("prop_changed", Callable(self, "on_prop_changed"))
			if index == 0:
				prop_button.active = true
				active_prop_path = p
			$VBox/Margin/Scroll/Buttons.add_child(prop_button)
			index += 1
		

### GETTERS

func find_prop_scenes(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547

	while true:
		var file = dir.get_next()
		if file == "":
			break
		if file.ends_with(".tscn"):
				files.append(path + file)
			
	return files

### SIGNALS

func on_prop_changed(prop_path):
	editor.set_tool("entity", "prop")
	active_prop_path = prop_path
	for b in $VBox/Margin/Scroll/Buttons.get_children():
		if b.prop_path == active_prop_path: #this is weird, we should have already done this. for extra security in case it was activated another way?
			b.activate()
	
	emit_signal("prop_changed", prop_path)
