extends Control

var level: String

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	self.text = (level.trim_prefix("res://src/Level/")).trim_suffix(".tscn")
	if level.find("/CloudFactory") != -1:
		self.set("theme_override_colors/font_color", Color(0.4, 0.666667, 0.8))
	if level.find("/Coast") != -1:
		self.set("theme_override_colors/font_color", Color(0.8, 0.4, 0.4))
	if level.find("/Village") != -1:
		self.set("theme_override_colors/font_color", Color(0.534375, 0.8, 0.4))



func _on_LevelButton_pressed():
	w.change_level_via_code(level, false)
