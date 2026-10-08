extends Control

var path: String

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	self.text = path.get_file().get_basename()
	#if group = "XXXX"
		#self.set("theme_override_colors/font_color", Color(0.4, 0.666667, 0.8))
	if path.contains("EnemyDebug"):
		self.set("theme_override_colors/font_color", Color(0.8, 0.4, 0.4))
	#if group = "YYYY"
		#self.set("theme_override_colors/font_color", Color(0.534375, 0.8, 0.4))



func _on_LevelButton_pressed():
	w.change_level_via_code(path, false)
