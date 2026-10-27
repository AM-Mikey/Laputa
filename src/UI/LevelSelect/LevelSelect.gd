extends Control

const LEVELBUTTON = preload("res://src/UI//LevelSelect/LevelButton.tscn")

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)

	for i in get_level_array("res://src/Level"):
		if i.rfind(".tscn"):
			var level_button = LEVELBUTTON.instantiate()
			level_button.path = i
			$MarginContainer/ScrollContainer/VBox/HBox/None/VBox.add_child(level_button)
	for j in get_level_array("res://src/Level/EnemyDebug"):
		if j.rfind(".tscn"):
			var level_button = LEVELBUTTON.instantiate()
			level_button.path = j
			$MarginContainer/ScrollContainer/VBox/HBox/EnemyDebug/VBox.add_child(level_button)

	var first_button = $MarginContainer/ScrollContainer/VBox/HBox/None/VBox.get_child(0)
	first_button.grab_focus()


func get_level_array(path) -> Array:
	var out = []
	var level_dir = DirAccess.open(path)
	level_dir.list_dir_begin()
	while true:
		var file = level_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				out.append(path + "/" + file)
	level_dir.list_dir_end()
	return out



### SIGNALS ###

func _on_Return_pressed():
	if w.has_node("MenuLayer/PauseMenu"):
		w.get_node("MenuLayer/PauseMenu").do_focus()
	if w.has_node("MenuLayer/Title"):
		w.get_node("MenuLayer/Title").do_focus()
	queue_free()

func _resolution_scale_changed(resolution_scale):
	set_deferred("size", get_tree().get_root().size / resolution_scale)
