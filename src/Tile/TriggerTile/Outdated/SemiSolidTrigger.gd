extends TileMap

const SEMISOLID = preload("res://src/Trigger/SemiSolid.tscn")

onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	var semi_solid_tiles = get_used_cells_by_id(0)

	for s in semi_solid_tiles:
		var semi_solid = SEMISOLID.instance()
		triggers.add_child(semi_solid)
		semi_solid.global_position = s * 16

	visible = false
