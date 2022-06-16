extends Control

const KEY_GUIDE = preload("res://src/UI/KeyGuide.tscn")
const LEVEL = preload("res://src/UI/LevelSelect/LevelSelect.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")
const TITLE = preload("res://src/UI/TitleScreen.tscn")

onready var world = get_tree().get_root().get_node("World")

func _ready():
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()
	focus()

func _input(event):
	if event.is_action_pressed("pause") and get_tree().paused and not world.has_node("UILayer/Options"):
		unpause()

func unpause():
	if world.has_node("UILayer/HUD"):
		world.get_node("UILayer/HUD").visible = true
	if world.has_node("UILayer/DialogBox"):
		world.get_node("UILayer/DialogBox").visible = true
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

func _on_KeyGuide_pressed():
	var key_guide = KEY_GUIDE.instance()
	get_parent().add_child(key_guide)
	key_guide.focus()
	

func _on_Level_pressed():
	var level = LEVEL.instance()
	get_parent().add_child(level)

func _on_Quit_pressed():
	var title = TITLE.instance()
	if not world.has_node("UILayer/TitleScreen"):
		world.get_node("UILayer").add_child(title)
	queue_free()

func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale



