tool
extends Control

signal update(data)
var data
var config_manager
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_Button_pressed():
	$Node/FileDialog.show()
	pass # Replace with function body.

func update_data(path):
	data = path
	emit_signal("update",data)
	var parts = data.split("/") as Array
	parts.invert()
	$HBoxContainer/Label.text = parts[0].split(".")[0]
	pass

func _on_FileDialog_file_selected(path):
	update_data(path)
	pass # Replace with function body.


func _on_Edit_pressed():
	var path = ProjectSettings.globalize_path(data)
	
	OS.execute(ProjectSettings.get_setting("tiled_tools/tiled_path"),[path])
	pass # Replace with function body.
