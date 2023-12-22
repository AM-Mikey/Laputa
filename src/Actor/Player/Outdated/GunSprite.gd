extends Sprite2D

func _on_Juniper_guns_updated(guns):
	if not guns.is_empty():
		texture = guns.front().texture
