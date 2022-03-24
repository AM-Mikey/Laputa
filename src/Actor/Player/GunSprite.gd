extends Sprite

func _on_Juniper_guns_updated(guns):
	if not guns.empty():
		texture = guns.front().texture
