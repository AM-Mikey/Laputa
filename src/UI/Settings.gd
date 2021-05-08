extends Control
onready var display_mode = $MarginContainer/VBoxContainer/DisplayMode

func _ready():
	display_mode.add_item("Windowed")
	display_mode.add_item("Borderless")
	display_mode.add_item("Fullscreen")



func _on_DisplayMode_item_selected(index):
	print("display settings changed")
	
	if index == 0:
		ProjectSettings.set_setting("display/window/size/borderless", false)
		ProjectSettings.set_setting("display/window/size/fullscreen", false)
	if index == 1:
		ProjectSettings.set_setting("display/window/size/borderless", true)
		ProjectSettings.set_setting("display/window/size/fullscreen", false)
	if index == 2:
		ProjectSettings.set_setting("display/window/size/borderless", false)
		ProjectSettings.set_setting("display/window/size/fullscreen", true)





func _on_PixelSnap_toggled(button_pressed):
	ProjectSettings.set_setting("rendering/quality/2d/use_pixel_snap", button_pressed)


func _on_Reset_pressed():
	pass # Replace with function body.


func _on_Save_pressed():
	queue_free()
