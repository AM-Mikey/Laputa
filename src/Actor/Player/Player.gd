extends Actor
class_name Player, "res://assets/Icon/PlayerIcon.png"



signal inventory_updated(inventory)


onready var HUD = get_tree().get_root().get_node("World/UILayer/HUD")
