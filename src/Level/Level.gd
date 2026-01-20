extends Node2D

const DB = preload("res://src/Dialog/DialogBox.tscn")
const KILL_BOX = preload("res://src/Trigger/KillBox.tscn")
enum LevelType {NORMAL, PLAYERLESS_CUTSCENE}

@export var editor_hidden = false
@export var level_name: String
@export var level_type: LevelType
@export var music: String
@export_file("*.json") var dialog_json: String
@export var conversation: String

var time_created: Dictionary

@onready var w = get_tree().get_root().get_node("World")


func _ready():
	add_to_group("Levels")
	if has_node("Notes"):
		get_node("Notes").visible = false
	setup_kill_box()

	if level_type == LevelType.PLAYERLESS_CUTSCENE:
		do_playerless_cutscene()

	merge_one_way_ssp_tile()

	if not am.music_queue.is_empty():
		am.fade_music()
		await am.fadeout_finished
	if not w.has_node("UILayer/TitleScreen"):
		if music == "":
			pass
		else:
			am.play_music(music)

func merge_one_way_ssp_tile() -> void:
	for i in $TileMap.get_children():
		i.fix_invalid_tiles()
	for child in $Triggers.get_children():
		if (child is StaticBody2D):
			child.queue_free()

	# Generate merged ssp tilemap geometry (Assuming geometry does not have hole when merged)
	var TileTransformRadian: Dictionary = {
		0: 0,
		TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H: PI / 2,
		TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V: PI,
		TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V: 3 * PI / 2,
	}


	var used_tiles_ssp_collision: Array[PackedVector2Array] = []
	for layer: TileMapLayer in $TileMap.get_children():
		var cell_size: Vector2i = layer.tile_set.tile_size
		for cell in layer.get_used_cells():
			var cell_data: TileData = layer.get_cell_tile_data(cell)
			if not (cell_data):
				break
			var number_of_cell_polygon: int = cell_data.get_collision_polygons_count(1)
			if number_of_cell_polygon > 0:
				var rotated_flag: int = layer.get_cell_alternative_tile(cell) & (TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V)
				for p_idx in range(number_of_cell_polygon):
					var cell_polygon: PackedVector2Array = cell_data.get_collision_polygon_points(1, p_idx)
					var transformed_polygon: PackedVector2Array = []
					if (TileTransformRadian.has(rotated_flag)):
						var rotated_radian: float = TileTransformRadian[rotated_flag]
						for point in cell_polygon:
							transformed_polygon.append(point.rotated(rotated_radian) + (Vector2(cell) + Vector2.ONE / 2) * Vector2(cell_size))
					else:
						var flipped_normal = Vector2.ONE
						match rotated_flag:
							TileSetAtlasSource.TRANSFORM_FLIP_H:
								flipped_normal = Vector2(-1, 1)
							TileSetAtlasSource.TRANSFORM_FLIP_V:
								flipped_normal = Vector2(1, -1)
							TileSetAtlasSource.TRANSFORM_TRANSPOSE:
								flipped_normal = Vector2(-1, -1)
						for point in cell_polygon:
							transformed_polygon.append(point * flipped_normal + (Vector2(cell) + Vector2.ONE / 2) * Vector2(cell_size))
					used_tiles_ssp_collision.append(transformed_polygon)

	var merged_polygon: Array[PackedVector2Array] = []
	var old_size: int = used_tiles_ssp_collision.size() + 1
	while (old_size > used_tiles_ssp_collision.size()):
		old_size = used_tiles_ssp_collision.size()
		if (used_tiles_ssp_collision.size() < 2):
			break
		var polygon_a = used_tiles_ssp_collision.pop_back()
		var polygon_b = used_tiles_ssp_collision.pop_back()
		merged_polygon.append_array(Geometry2D.merge_polygons(polygon_a, polygon_b))
		while (used_tiles_ssp_collision.size() > 0):
			var new_polygon_in_merge = true
			for i in range(merged_polygon.size()):
				polygon_a = merged_polygon[i]
				polygon_b = used_tiles_ssp_collision[used_tiles_ssp_collision.size() - 1]
				var res_polygon = Geometry2D.merge_polygons(polygon_a, polygon_b)
				if (res_polygon.size() == 1):
					merged_polygon[i] = res_polygon[0]
					used_tiles_ssp_collision.pop_back()
					new_polygon_in_merge = false
					break
			if (new_polygon_in_merge):
				merged_polygon.append(used_tiles_ssp_collision.pop_back())
		used_tiles_ssp_collision = merged_polygon
		merged_polygon = []

	var static_body: StaticBody2D = StaticBody2D.new()
	static_body.name = "SSP"
	static_body.collision_layer = 0
	static_body.set_collision_layer_value(10, true)
	$Triggers.add_child(static_body)

	for polygon in used_tiles_ssp_collision:
		var polygon_node: CollisionPolygon2D = CollisionPolygon2D.new()
		polygon_node.polygon = polygon
		polygon_node.one_way_collision = true
		static_body.add_child(polygon_node)


func do_playerless_cutscene():
	if w.has_node("UILayer/DialogBox"): #clear old dialog box if there is one
		w.get_node("UILayer/DialogBox").exit()

	var dialog_box = DB.instantiate()
	dialog_box.connect("dialog_finished", Callable(self, "on_dialog_finished"))
	get_tree().get_root().get_node("World/UILayer").add_child(dialog_box)
	dialog_box.start_printing(dialog_json, conversation)
	print("starting conversation")

func setup_kill_box():
	var kill_box = KILL_BOX.instantiate()
	var ll = get_node("LevelLimiter")
	var bottom_distance = ll.global_position.y + ll.size.y
	var forgiveness = 64
	kill_box.global_position = Vector2(ll.global_position.x, bottom_distance + forgiveness)
	kill_box.get_node("CollisionShape2D").position = Vector2.ZERO
	kill_box.get_node("CollisionShape2D").shape.size = Vector2(ll.size.x, 16)
	$Triggers.add_child(kill_box)

func exit_level():
	queue_free()

func save_changes():
	var ll = get_node("LevelLimiter")
	ll.background_resource.texture = ll.texture
	ll.background_resource.layers = ll.layers
	ll.background_resource.layer_scales = ll.layer_scales
	ll.background_resource.layer_height_offsets = ll.layer_height_offsets
	ll.background_resource.horizontal_speed = ll.horizontal_speed
	ll.background_resource.tile_mode = ll.tile_mode
	ll.background_resource.back_tile_mode = ll.back_tile_mode
