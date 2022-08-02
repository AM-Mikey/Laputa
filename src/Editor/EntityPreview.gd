extends Node2D

var entity_path: String

func _ready():
	var entity = load(entity_path).instance()
	var sprite = entity.get_node("Sprite")
	add_child(sprite.duplicate())
	add_to_group("Previews")
