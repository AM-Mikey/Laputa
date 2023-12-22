extends TileMap

const LADDER = preload("res://src/Trigger/Ladder.tscn")

@onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	for l in get_used_cells_by_id(0):
		var ladder = LADDER.instantiate()
		triggers.add_child(ladder)
		ladder.global_position = l * 16
	
	visible = false
