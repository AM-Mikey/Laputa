extends MarginContainer

@onready var w = get_tree().get_root().get_node("World")

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)



### SIGNALS ###

func _resolution_scale_changed(_resolution_scale):
	size = get_tree().get_root().size / Vector2i(w.dl.scale)
