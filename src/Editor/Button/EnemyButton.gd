extends MarginContainer

signal enemy_changed(enemy_path)

var enemy_path: String
var enemy_name: String
var active = false

func _ready():
	add_to_group("EnemyButtons")
	$HBox/Button.text = enemy_name
	$PanelActive.visible = active


func on_pressed():
	activate()
	emit_signal("enemy_changed", enemy_path)


func activate():
	for e in get_tree().get_nodes_in_group("EnemyButtons"):
		e.deactivate()
	$PanelActive.visible = true
	active = true

func deactivate():
	$PanelActive.visible = false
	active = false
