@icon("res://assets/Icon/ItemIcon.png")
extends Resource
class_name Item

@export var display_name: String = ""
@export var id: String = ""
@export var texture: Texture2D
@export_multiline var description: String = "This item is null. If you're reading this, this is an error."
@export var price: int = 0
@export var type: String = ""
