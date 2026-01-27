extends Node

const NW = Vector2i(-1, -1)
const N = Vector2i(0, -1)
const NE = Vector2i(1, -1)
const W = Vector2i(-1, 0)
const SELF = Vector2i(0, 0)
const E = Vector2i(1, 0)
const SW = Vector2i(-1, 1)
const S = Vector2i(0, 1)
const SE = Vector2i(1, 1)

var active_tile_map_cells = []

@onready var w = get_tree().get_root().get_node("World")
@onready var tile_map = w.current_level.get_node("TileMap")


#func _ready():
	#do_auto_tile()


func do_auto_tile(start_coords, start_layer):
	var data = tile_map.get_child(start_layer).get_cell_tile_data(start_coords)
	var auto_tile_group = data.get_custom_data("auto_tile_group")
	if auto_tile_group != "":
		if auto_tile_group == "backdirt":
			var group = "backdirt"

			var connected_cells = find_all_connected_cells(start_coords, start_layer, group)
			print(connected_cells)
			active_tile_map_cells.append(start_coords)
			if !connected_cells.is_empty():
				find_cells_recursive(connected_cells, start_layer, group)

			for i in active_tile_map_cells:
				pattern_backdirt(start_layer, i)
			#print("a: ", active_tile_map_cells)
			active_tile_map_cells = []
		else:
			get_auto_tile_directions(auto_tile_group)


func find_cells_recursive(coords_array, layer, group):
	for i in coords_array:
		if !active_tile_map_cells.has(i):
			var connected_cells = find_all_connected_cells(i, layer, group)
			active_tile_map_cells.append(i)
			if !connected_cells.is_empty():
				find_cells_recursive(connected_cells, layer, group)


func find_all_connected_cells(coords, layer, group) -> Array:
	var out = []
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
				out.append(neighbor)
	return out




func pattern_backdirt(layer, coords):
	var dict = get_auto_tile_directions("backdirt")
	var group = dict["all"]

	var non_connections = []

	if !is_group_in_direction(group, layer, coords, N):
		non_connections.append(N)
	if !is_group_in_direction(group, layer, coords, S):
		non_connections.append(S)
	if !is_group_in_direction(group, layer, coords, W):
		non_connections.append(W)
	if !is_group_in_direction(group, layer, coords, E):
		non_connections.append(E)

	var new_atlas_coords = dict["c"].pick_random() #default to center
	match non_connections:
		[N,S,W,E]:
			pass
			#print("single")
			# TODO: Make this handle empty connection groups..?
			# Or then just require the tileset editor to put "north" as also "north-west" and "north-east"...
		[N,W]:
			new_atlas_coords = dict["nw"].pick_random()
		[N,E]:
			new_atlas_coords = dict["ne"].pick_random()
		[S,W]:
			new_atlas_coords = dict["sw"].pick_random()
		[S,E]:
			new_atlas_coords = dict["se"].pick_random()
		[N]:
			new_atlas_coords = dict["n"].pick_random()
		[S]:
			new_atlas_coords = dict["s"].pick_random()
		[W]:
			new_atlas_coords = dict["w"].pick_random()
		[E]:
			new_atlas_coords = dict["e"].pick_random()


	var tile_map_layer: TileMapLayer = tile_map.get_child(layer)
	tile_map_layer.set_cell(coords, 0, new_atlas_coords)



### HELPERS ###

func get_auto_tile_directions(auto_tile_group) -> Dictionary:
	var out = {}
	out["all"] = [] #all tiles in group
	var source = tile_map.get_child(0).tile_set.get_source(0)

	for x in source.texture_region_size.x:
		for y in source.texture_region_size.y:
			var coords = Vector2i(x, y)
			if source.get_tile_at_coords(coords) != Vector2i(-1, -1): #tile exists
				var tile_data = source.get_tile_data(Vector2i(x, y), 0) #alternative id is always 0
				if tile_data.has_custom_data("auto_tile_group"):
					if auto_tile_group == tile_data.get_custom_data("auto_tile_group"): #the right group
						if tile_data.has_custom_data("auto_tile_direction"):
							out["all"].append(coords)
							var auto_tile_directions: String = tile_data.get_custom_data("auto_tile_direction")
							# TODO: Separate on commas and append to all the directions
							var directions = auto_tile_directions.split(",")
							print("YEAH")
							for auto_tile_direction in directions:
								print(auto_tile_direction)
								if out.has(auto_tile_direction):
									out[auto_tile_direction].append(coords)
								else:
									out[auto_tile_direction] = [coords]
	return out


func is_group_in_direction(group, layer, coords, direction) -> bool:
	var tile_map_layer: TileMapLayer = tile_map.get_child(layer)
	var cell_atlas_coords = tile_map_layer.get_cell_atlas_coords(coords + direction)
	if group.has(cell_atlas_coords):
		return true
	else:
		return false
