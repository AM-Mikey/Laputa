extends Node


onready var root = get_tree().get_root()


# Called when the node enters the scene tree for the first time.
func _ready():
	var viewport2 = root
	root.add_child(viewport2)
