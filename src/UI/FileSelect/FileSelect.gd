extends MarginContainer

onready var world = get_tree().get_root().get_node("World")


func _ready():
		var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
		on_viewport_size_changed()
	
	
	

func on_viewport_size_changed():
	rect_size = get_tree().get_root().size / world.resolution_scale
