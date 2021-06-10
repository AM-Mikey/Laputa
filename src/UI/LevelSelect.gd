extends Control

const LEVELBUTTON = preload("res://src/UI/LevelButton.tscn")


func _ready():
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

	for l in levels:
		if l.rfind(".tscn"):
			var level_button = LEVELBUTTON.instance()
			level_button.level = l
			$ScrollContainer/VBoxContainer.add_child(level_button)
		else:
			pass
		
