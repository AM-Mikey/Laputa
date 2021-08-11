extends Control

const LEVELBUTTON = preload("res://src/UI/LevelButton.tscn")

onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	
	var nones = []
	var coasts = []
	var villages= []
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
				nones.append("res://src/Level/%s" %file)
	level_dir.list_dir_end()
	
	demo_dir.open("res://src/Level/Coast")
	demo_dir.list_dir_begin()
	while true:
		var file = demo_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				coasts.append("res://src/Level/Coast/%s" %file)
	demo_dir.list_dir_end()
	
	demo_dir.open("res://src/Level/Village")
	demo_dir.list_dir_begin()
	while true:
		var file = demo_dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".tscn"):
				villages.append("res://src/Level/Village/%s" %file)
	demo_dir.list_dir_end()
	
#	demo_dir.open("res://src/Level/CloudFactory")
#	demo_dir.list_dir_begin()
#	while true:
#		var file = demo_dir.get_next()
#		if file == "":
#			break
#		elif not file.begins_with("."):
#			if file.ends_with(".tscn"):
#				nones.append("res://src/Level/CloudFactory/%s" %file)
#	demo_dir.list_dir_end()

	for n in nones:
		if n.rfind(".tscn"):
			var level_button = LEVELBUTTON.instance()
			level_button.level = n
			$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/None/VBoxContainer.add_child(level_button)
	
	for c in coasts:
		if c.rfind(".tscn"):
			var level_button = LEVELBUTTON.instance()
			level_button.level = c
			$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/Coast/VBoxContainer.add_child(level_button)
		
	for v in villages:
		if v.rfind(".tscn"):
			var level_button = LEVELBUTTON.instance()
			level_button.level = v
			$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/Village/VBoxContainer.add_child(level_button)

	########
	var first_button = $MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/None/VBoxContainer.get_child(0)
	
	first_button.grab_focus()

func _on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale


func _on_Return_pressed():
	if world.has_node("UILayer/PauseMenu"):
		world.get_node("UILayer/PauseMenu").focus()
	if world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer/TitleScreen").focus()
	queue_free()
