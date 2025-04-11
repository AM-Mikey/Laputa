extends MarginContainer

signal level_selected(level_path)

var level_path: String
var level_name: String
var active = false

func _ready():
	$HBox/Button.text = level_name
	$PanelActive.visible = active


func on_pressed():
	activate()
	emit_signal("level_selected", level_path)


func activate():
	for e in get_tree().get_nodes_in_group("LevelButtons"):
		e.deactivate()
	$PanelActive.visible = true
	active = true

func deactivate():
	$PanelActive.visible = false
	active = false
