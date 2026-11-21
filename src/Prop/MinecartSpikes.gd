extends "res://src/Prop/Minecart.gd"

## Minecart with spikes on one side.
## Everything comes from Minecart.gd; override only the functions/values that differ for the spiked cart
## here (call super() inside an override to keep the base behaviour as well).


func _init():
	ICON = preload("res://assets/Prop/MinecartSpikesIcon.png")
