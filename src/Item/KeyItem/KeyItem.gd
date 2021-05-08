extends Resource
class_name KeyItem, "res://assets/Icon/KeyItemIcon.png"

export var item_name: String = "Null Item"
export var texture: Texture = load("res://assets/Item/KeyItem/Necklace.png")
export(String, MULTILINE) var description = "This item is null. If you're reading this, this is an error."
