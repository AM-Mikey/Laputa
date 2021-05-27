extends TileMap

const LADDER = preload("res://src/Trigger/Ladder.tscn")

onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	var ladder_top_tiles = get_used_cells_by_id(0)

	for l in ladder_top_tiles:
		var ladder_size = 1
		var below = Vector2(l.x, l.y + 1)
		while get_cellv(below) == 1: #ladder section id is 1
			ladder_size +=1
			below.y += 1
		
		var ladder = LADDER.instance()
		triggers.add_child(ladder)
		ladder.global_position = l * 16
		ladder.scale.y = ladder_size

	visible = false
