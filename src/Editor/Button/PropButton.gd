extends MarginContainer

signal prop_changed(enemy_path)

var prop_path: String
var prop_name: String
var prop_icon: Texture2D
var active = false

func _ready():
	%Label.text = prop_name
	%TextureRect.texture = prop_icon
	%PanelActive.visible = active

func activate():
	for e in get_tree().get_nodes_in_group("PropButtons"):
		e.deactivate()
	%PanelActive.visible = true
	%Label.add_theme_color_override("font_color", Color(0.969, 0.886, 0.718, 1.0))
	active = true

func deactivate():
	%PanelActive.visible = false
	%Label.add_theme_color_override("font_color", Color(0.443, 0.561, 0.561))
	active = false


func _on_Button_pressed():
	activate()
	emit_signal("prop_changed", prop_path)
