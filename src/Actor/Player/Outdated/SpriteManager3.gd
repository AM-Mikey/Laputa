@tool
extends Node2D


@export var hframe: int: set = on_hframe_changed


@onready var sprite = $Sprite2D



func on_hframe_changed(new_hframe):
	sprite.frame_coords.x = new_hframe



func _on_Sprite_texture_changed():
	sprite.hframes = sprite.texture.get_width() /32
	sprite.vframes = sprite.texture.get_height() /32
