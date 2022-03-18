extends MarginContainer

onready var w = get_tree().get_root().get_node("World")

func _ready():
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
	on_viewport_size_changed()

func _on_return():
	if w.has_node("UILayer/PauseMenu"):
		w.get_node("UILayer/PauseMenu").focus()
	if w.has_node("UILayer/TitleScreen"):
		w.get_node("UILayer/TitleScreen").focus()
	queue_free()

func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / w.resolution_scale
