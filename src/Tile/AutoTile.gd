extends Node
class_name AutoTile#, "res://assets/Icon/NPCIcon.png"

@onready var w = get_tree().get_root().get_node("World")
@onready var tile_map = w.current_level.get_node("TileMap")

var current_layer

const NW = Vector2i(-1,-1)
const N = Vector2i(0,-1)
const NE = Vector2i(1,-1)
const W = Vector2i(-1,0)
const SELF = Vector2i(0,0)
const E = Vector2i(1,0)
const SW = Vector2i(-1,1)
const S = Vector2i(0,1)
const SE = Vector2i(1,1)


func do_auto_tile(start_coords: Vector2i, start_layer):

	var data: TileData = tile_map.get_child(start_layer).get_cell_tile_data(start_coords)
	if data == null:
		return

	var auto_tile_group = data.get_custom_data("auto_tile_group")

	var auto_tile_data = get_auto_tile_data(auto_tile_group)

	var active_tile_map_cells: Array [Vector2i] = []

	if auto_tile_data["type"] == "connections":
		var connected_cells = get_connected_neighbor_cells(start_coords, start_layer, auto_tile_group)
		active_tile_map_cells.append(start_coords)
		active_tile_map_cells.append_array(connected_cells)

		if data.get_custom_data("auto_tile_dont_replace") == true:
			active_tile_map_cells.erase(start_coords)

		for i in active_tile_map_cells:
			connection_pattern(start_layer, i, auto_tile_group)

	elif auto_tile_data["type"] == "modulate":
		# Could be moved into a function like modulate_pattern() but mehh
		var mod_size: Vector2i = auto_tile_data["mod_size"]
		var mod_origin: Vector2i = auto_tile_data["mod_origin"]
		var tile_x := start_coords.x % mod_size.x + mod_origin.x
		var tile_y := start_coords.y % mod_size.y + mod_origin.y
		var new_atlas_coords := Vector2i(tile_x, tile_y)
		var tile_map_layer: TileMapLayer = tile_map.get_child(start_layer)
		tile_map_layer.set_cell(start_coords, 0, new_atlas_coords)

func connection_pattern(layer, coords, pattern_name: String):
	var dict = get_auto_tile_data(pattern_name)
	var group = dict["all"]

	var non_connections: String = ""

	if !is_group_in_direction(group, layer, coords, N):
		non_connections += "n"
	if !is_group_in_direction(group, layer, coords, S):
		non_connections += "s"
	if !is_group_in_direction(group, layer, coords, W):
		non_connections += "w"
	if !is_group_in_direction(group, layer, coords, E):
		non_connections += "e"

	var atlas_coord_options = dict["c"] # Default to center

	if dict.has(non_connections):
		atlas_coord_options = dict[non_connections]

	var new_atlas_coords: Vector2i = atlas_coord_options.pick_random()

	var tile_map_layer: TileMapLayer = tile_map.get_child(layer)
	tile_map_layer.set_cell(coords, 0, new_atlas_coords)

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


### HELPERS ###

func get_connected_neighbor_cells(coords, layer, group) -> Array [Vector2i]:
	var out: Array [Vector2i] = []
	var neighbors = [
		coords + NW,
		coords + N,
		coords + NE,
		coords + W,
		coords + E,
		coords + SW,
		coords + S,
		coords + SE]

	var tile_map_layer: TileMapLayer = tile_map.get_child(layer)
	for neighbor in neighbors:
		if tile_map_layer.get_cell_atlas_coords(neighbor) != Vector2i(-1, -1): #cell is filled
			var neighbor_data = tile_map_layer.get_cell_tile_data(neighbor)
			if neighbor_data.get_custom_data("auto_tile_group") == group:
				if neighbor_data.get_custom_data("auto_tile_dont_replace") == true:
					continue
				out.append(neighbor)
	return out

func get_auto_tile_data(auto_tile_group) -> Dictionary:
	var out = {}
	out["all"] = [] #all tiles in group
	var source = tile_map.get_child(0).tile_set.get_source(0)

	# TODO: For modulates, find the rect size and do the shit lol
	var is_modulate_pattern: bool = false
	var is_connection_pattern: bool = false

	for x in source.texture_region_size.x:
		for y in source.texture_region_size.y:
			var coords = Vector2i(x, y)
			if source.get_tile_at_coords(coords) != Vector2i(-1, -1): #tile exists
				var tile_data = source.get_tile_data(Vector2i(x, y), 0) #alternative id is always 0
				if tile_data.has_custom_data("auto_tile_group") == false:
					continue
				if auto_tile_group != tile_data.get_custom_data("auto_tile_group"):
					continue
				if tile_data.has_custom_data("auto_tile_direction") == false:
					continue
				out["all"].append(coords)
				var auto_tile_directions: String = tile_data.get_custom_data("auto_tile_direction")
				var directions = auto_tile_directions.split(",", false)
				for auto_tile_direction in directions:
					var parsed_auto_tile_dir: String = ""
					# The directions need to be in a certain order, therefore this parsing is done
					for dir_letter in ["n", "s", "w", "e", "m"]:
						if auto_tile_direction.contains(dir_letter):
							parsed_auto_tile_dir += dir_letter
					if parsed_auto_tile_dir == "":
						if auto_tile_direction == "c":
							parsed_auto_tile_dir = "c"
						else:
							printerr("Unrecognized auto tile direction \"%s\"" % auto_tile_direction)
					if auto_tile_direction == "m":
						is_modulate_pattern = true
					else:
						is_connection_pattern = true
					if out.has(parsed_auto_tile_dir):
						out[parsed_auto_tile_dir].append(coords)
					else:
						out[parsed_auto_tile_dir] = [coords]
	if is_modulate_pattern and is_connection_pattern:
		printerr("Auto-tile pattern %s contains both connection and modulate tiles!" % auto_tile_group)

	if is_modulate_pattern == true:
		out["type"] = "modulate"

	if is_connection_pattern == true:
		out["type"] = "connections"

	if is_modulate_pattern == true:
		var min_x: int = out["m"][0].x
		var max_x: int = min_x
		var min_y: int = out["m"][0].y
		var max_y: int = min_y
		for tile_atlas_pos: Vector2i in out["m"]:
			min_x = mini(tile_atlas_pos.x, min_x)
			max_x = maxi(tile_atlas_pos.x, max_x)
			min_y = mini(tile_atlas_pos.y, min_y)
			max_y = maxi(tile_atlas_pos.y, max_y)
		var size: Vector2i = Vector2i(max_x - min_x, max_y - min_y) + Vector2i(1, 1)
		#print("Mod pattern size: ", size)
		out["mod_size"] = size
		out["mod_origin"] = Vector2i(min_x, min_y)

	return out


func is_group_in_direction(group, layer, coords, direction) -> bool:
	var tile_map_layer: TileMapLayer = tile_map.get_child(layer)
	var cell_atlas_coords = tile_map_layer.get_cell_atlas_coords(coords + direction)
	if group.has(cell_atlas_coords):
		return true
	else:
		return false
