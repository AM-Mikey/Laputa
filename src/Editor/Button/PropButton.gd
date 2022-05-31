extends MarginContainer

signal prop_changed(enemy_path)

var prop_path: String
var prop_name: String
var active = false

func _ready():
	add_to_group("PropButtons")
	$HBox/Button.text = prop_name
	$PanelActive.visible = active


func on_pressed():
	activate()
	emit_signal("prop_changed", prop_path)


func activate():
	for e in get_tree().get_nodes_in_group("PropButtons"):
		e.deactivate()
	$PanelActive.visible = true
	active = true

func deactivate():
	$PanelActive.visible = false
	active = false
