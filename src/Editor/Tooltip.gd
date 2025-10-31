extends MarginContainer

@onready var w = get_tree().get_root().get_node("World")
@onready var editor = get_parent().get_parent()

func _process(_delta):
	var mouse_pos = w.get_global_mouse_position()
	var cell_pos = editor.get_cell(mouse_pos)
	$HBox/Coordinates.text = str(cell_pos)


	var tile = editor.tile_map.get_child(0).get_cell_source_id(cell_pos)
	if tile != -1:
		$HBox/Tile.text = str(tile)
