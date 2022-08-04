extends MarginContainer



var mouse_pos

onready var w = get_tree().get_root().get_node("World")
onready var editor = get_parent().get_parent()

func _process(delta):
	var mouse_pos = w.get_global_mouse_position()
	var cell_pos = editor.get_cell(mouse_pos)
	$HBox/Coordinates.text = String(cell_pos)


	var tiles = []
	for m in editor.tile_collection.get_children():
		if m is TileMap:
			var tile = m.get_cellv(cell_pos)
			if tile != -1:
					tiles.append(tile)
	$HBox/Tile.text = String(tiles)
