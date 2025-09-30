extends MarginContainer

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)

func do_focus():
	$Margin/VBoxContainer/HBoxContainer/Return.grab_focus()



### SIGNALS ###

func _on_return():
	if w.has_node("MenuLayer/PauseMenu"):
		w.get_node("MenuLayer/PauseMenu").do_focus()
	if w.has_node("MenuLayer/TitleScreen"):
		w.get_node("MenuLayer/TitleScreen").do_focus()
	queue_free()

func _resolution_scale_changed(resolution_scale):
	size = get_tree().get_root().size / resolution_scale
