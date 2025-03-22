extends Node
class_name TileAnimator

var current_frames = {}
var groups = {}
var timers = {}
var frame_counts = {}

@onready var w = get_tree().get_root().get_node("World")
@onready var tile_map = w.current_level.get_node("TileMap")

func _ready():
	setup_animation_groups()
	setup()

func setup_animation_groups():
	var source = tile_map.tile_set.get_source(0)
	for column in source.texture_region_size.x:
		for row in source.texture_region_size.y:
			if source.get_tile_at_coords(Vector2i(column, row)) != Vector2i(-1, -1):
				var tile_data = source.get_tile_data(Vector2i(column, row), 0)
				if tile_data.has_custom_data("animation_group"):
					var animation_group = tile_data.get_custom_data("animation_group")
					if animation_group != "":
						if !groups.has(animation_group):
							groups[animation_group] = []
						if !current_frames.has(animation_group):
							current_frames[animation_group] = 0
	
	for layer in 4:
		for used_cell_pos in tile_map.get_used_cells(layer):
			var atlas_coords = tile_map.get_cell_atlas_coords(layer, used_cell_pos)
			var tile_data = tile_map.get_cell_tile_data(layer, used_cell_pos) #all frames need to be in the group
			if tile_data.has_custom_data("animation_group"):
				var animation_group = tile_data.get_custom_data("animation_group")
				if animation_group != "":
					groups[animation_group].append([layer, used_cell_pos, atlas_coords])

func setup(): #pass to class child
	pass

func next_animation_frame(group, group_name):
	var max_frame = frame_counts[group_name] - 1
	if current_frames[group_name] == max_frame:
		current_frames[group_name] = 0
	else:
		current_frames[group_name] += 1
	
	for tile in group:
		tile_map.set_cell(tile[0], tile[1], current_frames[group_name], tile[2])


func reset_animation():
	for group_name in current_frames.keys():
		current_frames[group_name] = 0
	for layer in 4:
		for used_cell_pos in tile_map.get_used_cells(layer):
			var atlas_coords = tile_map.get_cell_atlas_coords(layer, used_cell_pos)
			var is_animated = tile_map.tile_set.get_source(1).has_tile(atlas_coords) #check for a second frame
			if is_animated:
				tile_map.set_cell(layer, used_cell_pos, 0, atlas_coords)

func create_simple_timer(group: String, time: float):
	timers[group] = Timer.new()
	add_child(timers[group])
	timers[group].connect("timeout", Callable(self, "_timer_timeout").bind(group))
	timers[group].start(time)



### SIGNALS ###

func _timer_timeout(group):
	#print("finished ", group)
	next_animation_frame(groups[group], group)
