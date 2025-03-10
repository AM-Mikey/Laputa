extends Node

var current_frame = 0

@onready var w = get_tree().get_root().get_node("World")
@onready var tile_map = w.current_level.get_node("TileMap")

var waterfall_tiles := []
var grass_tiles := []

func _ready():
	setup_animation_groups()

func editor_enter():
	$WaterfallTimer.stop()
	$GrassTimer.stop()
	reset_animation()

func editor_exit():
	$WaterfallTimer.start()
	$GrassTimer.start()
	setup_animation_groups()

func setup_animation_groups():
	for layer in 4:
		for used_cell_pos in tile_map.get_used_cells(layer):
			var atlas_coords = tile_map.get_cell_atlas_coords(layer, used_cell_pos)
			var tile_data = tile_map.get_cell_tile_data(layer, used_cell_pos) #all frames need to be in the group
			var animation_group = tile_data.get_custom_data("animation_group")
			match animation_group:
				"waterfall":
					waterfall_tiles.append([layer, used_cell_pos, atlas_coords])
				"grass":
					grass_tiles.append([layer, used_cell_pos, atlas_coords])


func next_animation_frame(group):
	var max_frame = tile_map.tile_set.get_source_count() - 1
	if current_frame == max_frame: current_frame = 0
	else: current_frame += 1

	for tile in group:
		var has_next_frame = tile_map.tile_set.get_source(current_frame).has_tile(tile[2]) #check for next frame
		if has_next_frame:
			tile_map.set_cell(tile[0], tile[1], current_frame, tile[2])
		else:
			tile_map.set_cell(tile[0], tile[1], 0, tile[2])


func reset_animation():
	current_frame = 0
	for layer in 4:
		for used_cell_pos in tile_map.get_used_cells(layer):
			var atlas_coords = tile_map.get_cell_atlas_coords(layer, used_cell_pos)
			var is_animated = tile_map.tile_set.get_source(1).has_tile(atlas_coords) #check for a second frame
			if is_animated:
				tile_map.set_cell(layer, used_cell_pos, 0, atlas_coords)



### SIGNALS ###

func _on_WaterfallTimer_timeout():
	next_animation_frame(waterfall_tiles)

func _on_GrassTimer_timeout():
	next_animation_frame(grass_tiles)
