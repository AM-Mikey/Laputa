extends TileMap

const CONVEYOR = preload("res://src/Trigger/Conveyor.tscn")

@onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	var conveyor_left_tiles = get_used_cells_by_id(0)
	var conveyor_right_tiles = get_used_cells_by_id(1)

	for c in conveyor_left_tiles:
		var conveyor = CONVEYOR.instantiate()
		triggers.add_child(conveyor)
		conveyor.global_position = c * 16
		conveyor.direction = Vector2.LEFT

	for c in conveyor_right_tiles:
		var conveyor = CONVEYOR.instantiate()
		triggers.add_child(conveyor)
		conveyor.global_position = c * 16
		conveyor.direction = Vector2.RIGHT

	visible = false
