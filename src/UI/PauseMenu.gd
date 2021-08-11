extends Control

const OPTIONS = preload("res://src/UI/Options/Options.tscn")
const LEVEL = preload("res://src/UI/LevelSelect.tscn")

onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	focus()

func _input(event):
	if event.is_action_pressed("pause") and get_tree().paused and not world.has_node("UILayer/Options"):
		unpause()

func unpause():
	world.get_node("UILayer/HUD").visible = true
	get_tree().paused = false
	queue_free()

func focus():
	print("focused")
	$VBoxContainer/VBoxContainer/Return.grab_focus()

func _on_Return_pressed():
	unpause()

func _on_Options_pressed():
	var options = OPTIONS.instance()
	get_parent().add_child(options)

func _on_Level_pressed():
	var level = LEVEL.instance()
	get_parent().add_child(level)

func _on_Quit_pressed():
	get_tree().quit()

func _on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
