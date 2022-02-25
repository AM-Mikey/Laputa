extends MarginContainer

var layer


func _ready():
	$HBox/Label.text = layer.name
	$HBox/VisButton.pressed = !layer.visible


func _on_VisButton_toggled(button_pressed):
	layer.visible = !button_pressed


func _on_EditButton_toggled(button_pressed):
	pass
