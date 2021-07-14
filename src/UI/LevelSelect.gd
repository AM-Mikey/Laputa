extends Control

const LEVELBUTTON = preload("res://src/UI/LevelButton.tscn")

onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	
	var levels = []
	var level_dir = Directory.new()
	var demo_dir = Directory.new()
	
	level_dir.open("res://src/Level")
	level_dir.list_dir_begin()
	while true:
		var file = level_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				levels.append("res://src/Level/%s" %file)
	level_dir.list_dir_end()
	
	demo_dir.open("res://src/Level/Demo")
	demo_dir.list_dir_begin()
	while true:
		var file = demo_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				levels.append("res://src/Level/Demo/%s" %file)
	demo_dir.list_dir_end()
	
	demo_dir.open("res://src/Level/Demo/Coast")
	demo_dir.list_dir_begin()
	while true:
		var file = demo_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				levels.append("res://src/Level/Demo/Coast/%s" %file)
	demo_dir.list_dir_end()
	
	demo_dir.open("res://src/Level/Demo/Village")
	demo_dir.list_dir_begin()
	while true:
		var file = demo_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				levels.append("res://src/Level/Demo/Village/%s" %file)
	demo_dir.list_dir_end()
	
	demo_dir.open("res://src/Level/Demo/CloudFactory")
	demo_dir.list_dir_begin()
	while true:
		var file = demo_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				levels.append("res://src/Level/Demo/CloudFactory/%s" %file)
	demo_dir.list_dir_end()

	for l in levels:
		if l.rfind(".tscn"):
			var level_button = LEVELBUTTON.instance()
			level_button.level = l
			$MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(level_button)
		else:
			pass
	
	#add a sacrificial item because it clips last item otherwise
	var level_button = LEVELBUTTON.instance()
	$MarginContainer/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(level_button)

func _on_viewport_size_changed():
	$MarginContainer.rect_size = get_tree().get_root().size / world.resolution_scale


func _on_Return_pressed():
	queue_free()
