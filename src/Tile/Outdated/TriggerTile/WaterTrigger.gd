extends TileMap

const WATER = preload("res://src/Trigger/Water.tscn")

@onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	for c in get_used_cells_by_id(0):
		var water = WATER.instantiate()
		triggers.add_child(water)
		water.global_position = c * 16

	visible = false
