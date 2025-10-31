extends Node
class_name AutoTile#, "res://assets/Icon/NPCIcon.png"

var farback = TileMapLayer
var back = TileMapLayer
var front = TileMapLayer
var farfront = TileMapLayer
var current_layer

const NW = Vector2(-1,-1)
const N = Vector2(0,-1)
const NE = Vector2(1,-1)
const W = Vector2(-1,0)
const SELF = Vector2(0,0)
const E = Vector2(1,0)
const SW = Vector2(-1,1)
const S = Vector2(0,1)
const SE = Vector2(1,1)



### SETTERS ###

func set_random(cell, subpattern, layer = current_layer):
	var tile = subpattern[randi() % subpattern.size()]
	layer.set_cellv(cell, tile)

### GETTERS ###

func get_pattern_ids(pattern) -> Array:
	var ids = []
	for value in pattern.values():
		ids.append_array(value)
	return ids


func is_npt(cell, pattern, layer = current_layer) -> bool: #if non-pattern tile
	var tile = layer.get_cell_source_id(cell)
	return not(get_pattern_ids(pattern).has(tile))

func is_tile(cell, subpattern, layer = current_layer) -> bool: #if tile matches subpattern
	var tile = layer.get_cell_source_id(cell)
	return subpattern.has(tile)
