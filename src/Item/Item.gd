tool
extends Resource
class_name Item, "res://assets/Icon/ItemIcon.png"

export var item_name: String = "Null Item"
export var index: int = 0 setget _on_index_changed
export var texture: Texture
export(String, MULTILINE) var description = "This item is null. If you're reading this, this is an error."
export var price: int = 0

func _on_index_changed(new):
	index = new
	var cropped_texture = AtlasTexture.new()
	cropped_texture.atlas = load("res://assets/Item/Items.png")
	cropped_texture.region = Rect2((index % 8) * 32, (floor(index / 8)) * 16, 32, 16)
	
	texture = cropped_texture
	property_list_changed_notify()
