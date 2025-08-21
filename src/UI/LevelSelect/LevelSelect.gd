extends Control

const LEVELBUTTON = preload("res://src/UI//LevelSelect/LevelButton.tscn")

@onready var world = get_tree().get_root().get_node("World")

func _ready(): #TODO: update load and save to new file
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	
	var nones = []
	
	var level_dir = DirAccess.open("res://src/Level")
	level_dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	while true:
		var file = level_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				nones.append("res://src/Level/%s" %file)
	level_dir.list_dir_end()
	
	for n in nones:
		if n.rfind(".tscn"):
			var level_button = LEVELBUTTON.instantiate()
			level_button.level = n
			$MarginContainer/ScrollContainer/VBox/HBox/None/VBox.add_child(level_button)
	
	########
	var first_button = $MarginContainer/ScrollContainer/VBox/HBox/None/VBox.get_child(0)
	
	first_button.grab_focus()


func _on_Return_pressed():
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").do_focus()
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").do_focus()
	queue_free()

func on_viewport_size_changed():
	size = get_tree().get_root().size / world.resolution_scale
