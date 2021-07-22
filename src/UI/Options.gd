extends MarginContainer


onready var world = get_tree().get_root().get_node("World")

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()


func _on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
