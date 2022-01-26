extends Resource
class_name Item, "res://assets/Icon/ItemIcon.png"

export var item_name: String = "Null Item"
export var texture: Texture = load("res://assets/Item/Item/Necklace.png")
export(String, MULTILINE) var description = "This item is null. If you're reading this, this is an error."
