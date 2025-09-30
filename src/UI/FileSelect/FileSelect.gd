extends MarginContainer

@onready var world = get_tree().get_root().get_node("World")


func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)



### SIGNALS ###

func _resolution_scale_changed(resolution_scale):
	size = get_tree().get_root().size / resolution_scale
