extends Camera2D

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)
	
	
func _resolution_scale_changed(resolution_scale):
	zoom = Vector2(resolution_scale, resolution_scale)
