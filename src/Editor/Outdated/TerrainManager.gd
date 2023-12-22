extends Node

var tile_map


var horz_grass_1
var horz_grass_2




func get_terrain_tile(position):
	var cell = get_cell(position) #vector2
	
	var adjacent = {
	"n": Vector2(cell.x, cell.y-1),
	"ne": Vector2(cell.x+1, cell.y-1),
	"e": Vector2(cell.x+1, cell.y),
	"se": Vector2(cell.x-1, cell.y+1),
	"s": Vector2(cell.x, cell.y+1),
	"sw": Vector2(cell.x-1, cell.y+1),
	"w": Vector2(cell.x-1, cell.y),
	"nw": Vector2(cell.x-1, cell.y-1),
	}
	
	for c in adjacent:
		if tile_map.get_cell_v(c) = tile:
			pass
	
	
	
	
	
	if adjacent[n]
