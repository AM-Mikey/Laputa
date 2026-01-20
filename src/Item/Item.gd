@icon("res://assets/Icon/ItemIcon.png")
extends Resource
class_name Item

@export var item_name: String = "Null Item"
@export var texture: Texture2D
@export_multiline var description: String = "This item is null. If you're reading this, this is an error."
@export var price: int = 0
