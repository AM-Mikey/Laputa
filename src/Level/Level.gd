extends Node2D

export var level_name: String
export var music: String

onready var world = get_tree().get_root().get_node("World")

func _ready():
	add_to_group("Levels")
	if self.has_node("Camera2D"):
		var _size = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
		on_viewport_size_changed()
	
	if self.has_node("Notes"):
		get_node("Notes").visible = false
	

func on_viewport_size_changed():
	$Camera2D.zoom = Vector2(1 / world.resolution_scale, 1 / world.resolution_scale)
	

func exit_level():
	queue_free()
