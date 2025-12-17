extends Control

const LEVELBUTTON = preload("res://src/UI//LevelSelect/LevelButton.tscn")

@onready var world = get_tree().get_root().get_node("World")

func _ready(): #TODO: update load and save to new file
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)

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



### SIGNALS ###

func _on_Return_pressed():
	if world.has_node("MenuLayer/PauseMenu"):
		world.get_node("MenuLayer/PauseMenu").do_focus()
	if world.has_node("MenuLayer/TitleScreen"):
		world.get_node("MenuLayer/TitleScreen").do_focus()
	queue_free()

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / resolution_scale)
