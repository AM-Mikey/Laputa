extends MarginContainer

signal misc_changed(misc_path)

var misc_path: String
var misc_name: String
var active = false

func _ready():
	%Button.text = misc_name
	%PanelActive.visible = active


func on_pressed():
	activate()
	emit_signal("misc_changed", misc_path)


func activate():
	for e in get_tree().get_nodes_in_group("MiscButtons"):
		e.deactivate()
	%PanelActive.visible = true
	active = true

func deactivate():
	%PanelActive.visible = false
	active = false
