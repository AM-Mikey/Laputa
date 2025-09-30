extends Control

const KEY_GUIDE = preload("res://src/UI/KeyGuide.tscn")
const LEVEL_SELECT = preload("res://src/UI/LevelSelect/LevelSelect.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")
const TITLE = preload("res://src/UI/TitleScreen.tscn")

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	do_focus()
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)



func _input(event):
	if event.is_action_pressed("pause") and get_tree().paused and not w.has_node("MenuLayer/Options"):
		unpause()

func do_focus():
	$VBoxContainer/VBoxContainer/Return.grab_focus()

func unpause():
	w.ui.visible = true
	get_tree().paused = false
	queue_free()



### SIGNALS ###

func _on_Return_pressed():
	unpause()

func _on_Options_pressed():
	var options = OPTIONS.instantiate()
	w.ml.add_child(options)

func _on_KeyGuide_pressed():
	var key_guide = KEY_GUIDE.instantiate()
	w.ml.add_child(key_guide)
	key_guide.do_focus()
	

func _on_Level_pressed():
	var level_select = LEVEL_SELECT.instantiate()
	w.ml.add_child(level_select)

func _on_Quit_pressed():
	var title = TITLE.instantiate()
	if not w.ml.has_node("TitleScreen"):
		w.ml.add_child(title)
	queue_free()

func _resolution_scale_changed(resolution_scale):
	size = get_tree().get_root().size / resolution_scale
