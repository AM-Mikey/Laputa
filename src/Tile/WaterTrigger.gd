extends TileMap

const WATER = preload("res://src/Trigger/Water.tscn")
const AIR = preload("res://src/Trigger/Air.tscn")

onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	var water_tiles = get_used_cells_by_id(0)
	var air_tiles = get_used_cells_by_id(1)

	for w in water_tiles:
		var water = WATER.instance()
		triggers.add_child(water)
		water.global_position = w * 16

	for a in air_tiles:
		var air = AIR.instance()
		triggers.add_child(air)
		air.global_position = a * 16

	visible = false
