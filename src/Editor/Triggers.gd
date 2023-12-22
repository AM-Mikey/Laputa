extends MarginContainer

const TRIGGER_BUTTON = preload("res://src/Editor/Button/TriggerButton.tscn")

signal trigger_changed(trigger_path)

var triggers = {}
var active_trigger_path

@onready var editor = get_parent().get_parent().get_parent()

func _ready():
	setup_triggers()


func setup_triggers():
	var index = 0
	for p in find_trigger_scenes("res://src/Trigger/"):
		
		var trigger = load(p).instantiate()
		
		triggers[trigger.name] = trigger
		
		var trigger_button = TRIGGER_BUTTON.instantiate()
		trigger_button.trigger_path = p
		trigger_button.trigger_name = trigger.name
		trigger_button.connect("trigger_changed", Callable(self, "on_trigger_changed"))
		if index == 0:
			trigger_button.active = true
			active_trigger_path = p
		$VBox/Margin/Scroll/Buttons.add_child(trigger_button)
		index += 1
		

### GETTERS

func find_trigger_scenes(path):
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

func on_trigger_changed(trigger_path):
	editor.set_tool("entity", "trigger")
	active_trigger_path = trigger_path
	for b in $VBox/Margin/Scroll/Buttons.get_children():
		if b.trigger_path == active_trigger_path: #this is weird, we should have already done this. for extra security in case it was activated another way?
			b.activate()
	
	emit_signal("trigger_changed", trigger_path)
