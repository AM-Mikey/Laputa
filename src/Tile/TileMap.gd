extends TileMap

const LADDER = preload("res://src/Trigger/Ladder.tscn")


onready var triggers = get_parent().get_parent().get_node("Triggers")

func _ready():
	var ladder_array = get_used_cells_by_id(21) 

	
	for l in ladder_array:
		var ladder_size = 1
		var below = Vector2(l.x, l.y + 1)
		while get_cellv(below) == 20:
			ladder_size +=1
			below.y += 1
		print(ladder_size)
		
		var ladder = LADDER.instance()
		triggers.add_child(ladder)
		ladder.global_position = l * 16
		ladder.scale.y = ladder_size
