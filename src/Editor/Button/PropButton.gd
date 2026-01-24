extends MarginContainer

signal prop_changed(enemy_path)

var prop_path: String
var prop_name: String
var prop_sprite: Texture2D
var active = false

func _ready():
	%Label.text = prop_name
	%TextureRect.texture = prop_sprite
	%PanelActive.visible = active

func activate():
	for e in get_tree().get_nodes_in_group("PropButtons"):
		e.deactivate()
	%PanelActive.visible = true
	active = true

func deactivate():
	%PanelActive.visible = false
	active = false


func _on_Button_pressed():
	activate()
	emit_signal("prop_changed", prop_path)
