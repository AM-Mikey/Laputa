extends TileMap

const GRASS = preload("res://src/Prop/Grass.tscn")

onready var props = get_parent().get_parent().get_node("Props")

func _ready():
	var grass_tiles = get_used_cells_by_id(0)

	for g in grass_tiles:
		var grass = GRASS.instance()
		
		match int(g.x) % 4:
			1: grass.num = 1
			2: grass.num = 2
			3: grass.num = 3
			0: grass.num = 4
		
		grass.position = g * 16
		grass.position += Vector2(8, 16)
		props.add_child(grass)

	visible = false
