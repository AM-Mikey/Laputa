extends MarginContainer

signal trigger_changed(trigger_path)

var trigger_path: String
var trigger_name: String
var active = false

func _ready():
	add_to_group("TriggerButtons")
	$HBox/Button.text = trigger_name
	$PanelActive.visible = active


func on_pressed():
	activate()
	emit_signal("trigger_changed", trigger_path)


func activate():
	for e in get_tree().get_nodes_in_group("TriggerButtons"):
		e.deactivate()
	$PanelActive.visible = true
	active = true

func deactivate():
	$PanelActive.visible = false
	active = false
