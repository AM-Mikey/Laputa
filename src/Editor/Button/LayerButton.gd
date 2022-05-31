extends MarginContainer

signal layer_changed(layer)

var layer: TileMap
var active = false


func _ready():
	add_to_group("LayerButtons")
	$HBox/LayerButton.text = layer.name
	$HBox/VisButton.pressed = !layer.visible
	$PanelActive.visible = active


func _on_VisButton_toggled(button_pressed):
	layer.visible = !button_pressed


func _on_EditButton_toggled(button_pressed):
	pass


func _on_LayerButton_pressed():
	activate()
	emit_signal("layer_changed", layer)


func activate():
	for l in get_tree().get_nodes_in_group("LayerButtons"):
		l.get_node("PanelActive").visible = false
		l.active = false
	active = true
	$PanelActive.visible = true
