extends Camera2D

@onready var world = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("Cameras")

	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	
	
func on_viewport_size_changed():
	zoom = Vector2(world.resolution_scale, world.resolution_scale)
