@tool
@icon("res://assets/Icon/ItemIcon.png")
extends Resource
class_name Item

@export var item_name: String = "Null Item"
@export var index: int = 0: set = _on_index_changed
@export var texture: Texture2D
@export var description = "This item is null. If you're reading this, this is an error." # (String, MULTILINE)
@export var price: int = 0

func _on_index_changed(new):
	index = new
	var cropped_texture = AtlasTexture.new()
	cropped_texture.atlas = load("res://assets/Item/Items.png")
	cropped_texture.region = Rect2((index % 8) * 32, (floor(index / 8.0)) * 16, 32, 16)

	texture = cropped_texture
	notify_property_list_changed()
