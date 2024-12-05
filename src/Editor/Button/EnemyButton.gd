extends MarginContainer

signal enemy_changed(enemy_path)

var enemy_path: String
var enemy_name: String
var enemy_sprite: Texture2D
var active = false

func _ready():
	$VBox/HBox/Label.text = enemy_name
	$VBox/TextureRect.texture = enemy_sprite
	$PanelActive.visible = active

func activate():
	for e in get_tree().get_nodes_in_group("EnemyButtons"):
		e.deactivate()
	$PanelActive.visible = true
	active = true

func deactivate():
	$PanelActive.visible = false
	active = false


func _on_button_pressed():
	activate()
	emit_signal("enemy_changed", enemy_path)
