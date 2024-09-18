extends MarginContainer

signal layer_changed(layer)

var tile_map: Node
var layer_id: int
var active = false


func _ready():
	add_to_group("LayerButtons")
	$HBox/LayerButton.text = tile_map.get_layer_name(layer_id)
	if tile_map.get_layer_modulate(layer_id) == Color.TRANSPARENT:
		$HBox/VisButton.button_pressed = true
	else:
		$HBox/VisButton.button_pressed = false
	$PanelActive.visible = active


func _on_VisButton_toggled(button_pressed):
	if button_pressed:
		tile_map.set_layer_modulate(layer_id, Color.TRANSPARENT)
	else:
		tile_map.set_layer_modulate(layer_id, Color.WHITE)

func _on_EditButton_toggled(button_pressed):
	pass


func _on_LayerButton_pressed():
	activate()
	emit_signal("layer_changed", layer_id)


func activate():
	for l in get_tree().get_nodes_in_group("LayerButtons"):
		l.get_node("PanelActive").visible = false
		l.active = false
	active = true
	$PanelActive.visible = true
