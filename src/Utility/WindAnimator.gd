extends Node

export var wind_time = 0.1
export var invert_time = 0.1
export var tiles1 = [
	288, 289, 290, 291,
	320, 321, 322, 323,
	]
export var tiles2 = [
	304, 305, 306, 307,
	336, 337, 338, 339
]

var state = 1
var cycle_index = 0
var cycle_length = 8

onready var w = get_tree().get_root().get_node("World")
onready var tile_collection = w.current_level.get_node("Tiles")


func _ready():
	$Timer.start(wind_time)
	$InvertTimer.start(invert_time)



func replace_cycle_tiles(start, end, cycle):
	for m in tile_collection.get_children():
		if m is TileMap:
			var tiles_index = 0
			for t in start:
				var cells = m.get_used_cells_by_id(t)
				for c in cells:
					#print(c.x)
					if int(c.x) % cycle_length == cycle:
						#print("asdasd")
						m.set_cellv(c, end[tiles_index])
				tiles_index += 1


func replace_tiles(start, end):
	for m in tile_collection.get_children():
		if m is TileMap:
			var tiles_index = 0
			for t in start:
				var cells = m.get_used_cells_by_id(t)
				for c in cells:
					m.set_cellv(c, end[tiles_index])
				tiles_index += 1

func invert_tiles():
	for m in tile_collection.get_children():
		if m is TileMap:
			
			var tiles_index = 0
			for t in tiles1:
				var cells1 = m.get_used_cells_by_id(t)
				var cells2
				for t2 in tiles2:
					cells2 = m.get_used_cells_by_id(tiles2[tiles_index])
					
				for c in cells1:
					m.set_cellv(c, tiles2[tiles_index])
				for c in cells2:
					m.set_cellv(c, tiles1[tiles_index])
				
				tiles_index += 1

func invert_tiles_cylce(cycle):
	for m in tile_collection.get_children():
		if m is TileMap:
			
			var tiles_index = 0
			for t in tiles1:
				var cells1 = m.get_used_cells_by_id(t)
				var cells2
				for t2 in tiles2:
					cells2 = m.get_used_cells_by_id(tiles2[tiles_index])
					
				for c in cells1:
					if int(c.x) % cycle_length == cycle:
						m.set_cellv(c, tiles2[tiles_index])
				for c in cells2:
					if int(c.x) % cycle_length == cycle:
						m.set_cellv(c, tiles1[tiles_index])
				
				tiles_index += 1



### SIGNALS ###


func _on_Timer_timeout():
	$Timer.start(wind_time)
	invert_tiles_cylce(cycle_index)
	
#	yield(get_tree().create_timer(0.05), "timeout")
#	replace_cycle_tiles(tiles2, tiles1, cycle_index)
	
	cycle_index = 0 if cycle_index == cycle_length else cycle_index + 1 #increment cycle
	
	if cycle_index == 0: #change state
		match state:
			1: state = 2
			2: state = 1


func _on_InvertTimer_timeout():
	invert_tiles()
	$InvertTimer.start()
