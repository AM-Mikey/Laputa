extends MarginContainer

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()

func _on_return():
	if w.has_node("UILayer/UIGroup/PauseMenu"):
		w.get_node("UILayer/UIGroup/PauseMenu").do_focus()
	if w.has_node("UILayer/UIGroup/TitleScreen"):
		w.get_node("UILayer/UIGroup/TitleScreen").do_focus()
	queue_free()

func on_viewport_size_changed():
	size = get_tree().get_root().size / w.resolution_scale

func do_focus():
	$Margin/VBoxContainer/HBoxContainer/Return.grab_focus()
