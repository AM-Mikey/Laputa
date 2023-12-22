extends TileMap

const BREAK_BLOCK = preload("res://src/Prop/BreakBlock.tscn")
const BREAK_GRASS = preload("res://src/Prop/BreakGrass.tscn")


@onready var props = get_parent().get_parent().get_node("Props")

func _ready():
	var break_block_array = get_used_cells_by_id(0) 
	var break_grass_array = get_used_cells_by_id(1)
	
	for b in break_block_array:
		var break_block = BREAK_BLOCK.instantiate()
		props.add_child(break_block)
		break_block.global_position = b * 16
	for g in break_grass_array:
		var break_grass = BREAK_GRASS.instantiate()
		props.add_child(break_grass)
		break_grass.global_position = g * 16

	visible = false
	
