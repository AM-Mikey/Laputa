tool
extends TileMap

func _ready():
	if get_parent().get_parent():
		get_parent().get_parent().connect("tile_set_changed", self, "_on_tile_set_changed")
	
	_on_tile_set_changed()

func _on_tile_set_changed():
	tile_set = get_parent().get_parent().tile_set
