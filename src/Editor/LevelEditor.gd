extends Control

const LAYER = preload("res://src/Editor/Layer.tscn")




export(NodePath) var tiles_tab
export(NodePath) var layer_list


var tiles = {}
var active_tile: int

var layers = {}
var auto_layer = true
var multi_erase = false

var brush = "paint"
var mouse_start_pos
var lmb_held = false
var rmb_held = false
var shift_held = false
var ctrl_held = false

var past_operations = [] #[[op][op][op]]
var future_operations = [] #[[op][op][op]]
var active_operation = [] #[[subop][subop][subop]]


onready var w = get_tree().get_root().get_node("World")
onready var tile_collection = w.current_level.get_node("Tiles")
var tilemap
var tileset

func _ready():
	var _err = get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	#setup_tiles()
	#create_tileset_from_texture(load("res://assets/Tile/VillageMinimal.png"))
	load_tileset(tile_collection.get_child(0).tile_set.resource_path)
	setup_layers()

func create_tileset_from_texture(texture):
	tileset = TileSet.new()
	var rows = int(texture.get_size().y/16)
	var columns = int(texture.get_size().x/16)
	
	var id = 0
	while id < rows * columns:
		var x_pos = (id % columns) * 16
		var y_pos = floor(id / columns) * 16
		var region = Rect2(x_pos, y_pos, 16, 16)
		
		#if texture_alpha_check(texture, region):
		tileset.create_tile(id)
		tileset.tile_set_texture(id, texture)
		tileset.tile_set_region(id, region)
		id += 1
	
	get_node(tiles_tab).setup_tileset(tileset)
	
	for c in tile_collection.get_children():
		if c is TileMap:
			c.tile_set = tileset


func texture_alpha_check(texture, region) -> bool: #TODO does not work
	var image = Image.new()
	image.load(texture.resource_path)
	if image.get_rect(region).is_invisible():
		return true
	else:
		return false
	
	
	
	
	
#	var pixel_check_count = 0
#	var pixel_pos = Vector2.ZERO
	
#	for row in cropped.get_height():
#		for column in cropped.get_width():
#			var pixel = AtlasTexture.new()
#			pixel.atlas = texture
#			pixel.region = Rect2(column, row, 1, 1)
#			if pixel.has_alpha():
#				pixel_check_count += 1
#
#
#	#if pixel_check_count != 0:
#	print("pixel_check_count:", pixel_check_count)
#	if pixel_check_count == cropped.get_height() * cropped.get_width():
#		return true
#	else:
#		return false


func load_tileset(path):
	tileset = load(path)
	var texture = tileset.tile_get_texture(0)
	var rows = int(texture.get_size().y/16)
	var columns = int(texture.get_size().x/16)

	for c in tile_collection.get_children():
		if c is TileMap:
			c.tile_set = tileset

#	var id = 0 #tileset.get_last_unused_tile_id()
#	while id < rows * columns:
#		var x_pos = (id % columns) * 16
#		var y_pos = floor(id / columns) * 16
#		var region = Rect2(x_pos, y_pos, 16, 16)
#		tileset.tile_set_region(id, region)
#		id += 1
	
	get_node(tiles_tab).setup_tileset(tileset)
	

#func setup_tiles():
#	import_tileset()
#
#	var list_id = 0 #bug if tile id is 0?
#
#	for i in tileset.get_tiles_ids():
#		tiles[list_id] = i
#
#		var tile_name = tileset.tile_get_name(i)
#		get_node(tile_list).add_icon_item(get_tile_texture(i))
#		list_id += 1


func get_tile_texture(tile):
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = tileset.tile_get_texture(tile)
	tile_texture.region = tileset.tile_get_region(tile)
	return tile_texture


func _on_TileList_item_selected(index):
	active_tile = tiles[index]
	if auto_layer:
		change_layer(get_auto_layer())

func _unhandled_input(event):
	var mouse_pos = w.get_global_mouse_position()
	
	if event.is_action_pressed("editor_lmb") and active_tile:
		lmb_held = true
		future_operations.clear()
		mouse_start_pos = mouse_pos
		
		if shift_held:
			brush = "line"
		elif ctrl_held:
			brush = "box"
		else:
			brush = "paint"
			set_tiles([get_cell(mouse_pos)], active_tile)


	if event.is_action_released("editor_lmb"):
		lmb_held = false
		if brush == "line":
			set_tiles(get_line(mouse_start_pos, mouse_pos), active_tile)
		elif brush == "box":
			set_tiles(get_box(mouse_start_pos, mouse_pos), active_tile)
		
		if not active_operation.empty():
			past_operations.append(["set_tiles", active_operation.duplicate()])
			#print("active op: ", active_operation)
			active_operation.clear()



	if event.is_action_pressed("editor_rmb"):
		rmb_held = true
		future_operations.clear()
		mouse_start_pos = mouse_pos
		if shift_held:
			brush = "line"
		elif ctrl_held:
			brush = "box"
		else:
			brush = "paint"
			if multi_erase:
				set_tiles_on_all_layers([get_cell(mouse_pos)], -1)
			else:
				set_tiles([get_cell(mouse_pos)], -1)


	if event.is_action_released("editor_rmb"):
		rmb_held = false
		if brush == "line":
			set_tiles(get_line(mouse_start_pos, mouse_pos), -1)
		elif brush == "box":
			set_tiles(get_box(mouse_start_pos, mouse_pos), -1)
		
		if not active_operation.empty():
			var operation_name = "set_tiles_on_all_layers" if multi_erase else "set_tiles"
			past_operations.append([operation_name, active_operation.duplicate()])
			#print("active op: ", active_operation)
			active_operation.clear()




	if event is InputEventMouseMotion:
		if lmb_held and brush == "paint":
			set_tiles([get_cell(mouse_pos)], active_tile)
		if rmb_held and brush == "paint":
			if multi_erase:
				set_tiles_on_all_layers([get_cell(mouse_pos)], -1)
			else:
				set_tiles([get_cell(mouse_pos)], -1)
		
		hide_preview()
		if brush == "paint":
			preview_tiles([get_cell(mouse_pos)])
		
		elif lmb_held or rmb_held:
			if brush == "line":
				preview_tiles(get_line(mouse_start_pos, mouse_pos))
			if brush == "box":
				preview_tiles(get_box(mouse_start_pos, mouse_pos))
				



	if event.is_action_pressed("editor_ctrl"):
		ctrl_held = true
	if event.is_action_released("editor_ctrl"):
		ctrl_held = false
	if event.is_action_pressed("editor_shift"):
		shift_held = true
	if event.is_action_released("editor_shift"):
		shift_held = false

	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_Z and not event.is_echo():
		if ctrl_held and not shift_held:
			undo()
		if ctrl_held and shift_held:
			redo()


### OPERATIONS ###

func undo():
	var last = past_operations.pop_back()
	
	if last:
		future_operations.append(last)
		print("undoing operation: ", last)
		
		match last[0]:
			"set_tiles":
				for t in last[1]: #subops
					set_tiles([t[0]], t[2], false) #pos_array, old_tile, traced
#	else:
#		print("nothing left to undo!")


func redo():
	var next = future_operations.pop_back()
	
	if next:
		past_operations.append(next)
		print("redoing operation: ", next)
		
		match next[0]:
			"set_tiles":
				for t in next[1]: #subops
					set_tiles([t[0]], t[1], false) #pos_array, new_tile, traced
#	else:
#		print("nothing left to redo!")



func set_tiles(pos_array: Array, tile, traced = true):
	for pos in pos_array: #subops
		var old_tile = tilemap.get_cellv(pos)
		tilemap.set_cellv(pos, tile)
		if traced:
			for s in active_operation:
				if s[0] == pos: #positions match
					return
			active_operation.append([pos, tile, old_tile])

func set_tiles_on_all_layers(pos_array: Array, tile, traced = true): #TODO: finish this as it doesnt work right now
	for pos in pos_array: #subops
		for l in layers:
			var layer = layers[l]
			var old_tile = layer.get_cellv(pos)
			layer.set_cellv(pos, tile)
			if traced:
				for s in active_operation:
					if s[1] == pos: #positions match
						return
				active_operation.append([layer, pos, tile, old_tile])

### PREVIEW ###

func preview_tiles(pos_array: Array):
	for pos in pos_array:
		var sprite = Sprite.new()
		sprite.texture = get_tile_texture(active_tile)
		sprite.modulate = Color(1, 1, 1, 0.5)
		sprite.centered = false
		sprite.position = pos * 16
		tile_collection.add_child(sprite)

func hide_preview():
	for c in tile_collection.get_children():
		if c is Sprite:
			c.queue_free()



### GETTERS ###

func get_box(start, end) -> Array:
	var tiles = []
	var start_tile = get_cell(start)
	var end_tile = get_cell(end)
	
	var x_min = min(start_tile.x, end_tile.x)
	var x_max = max(start_tile.x, end_tile.x)
	var y_min = min(start_tile.y, end_tile.y)
	var y_max = max(start_tile.y, end_tile.y)
	
	for i in range(x_min, x_max + 1):
		for j in range(y_min, y_max + 1):
			tiles.append(Vector2(i, j))
	return tiles


func get_cell(mouse_pos) -> Vector2:
	var local_pos = tilemap.to_local(mouse_pos)
	var map_pos = tilemap.world_to_map(local_pos)
	return map_pos


func get_line(start, end) -> Array:
	var tiles = []
	var start_tile = get_cell(start)
	var end_tile = get_cell(end)
	
	var dx = end_tile.x - start_tile.x
	var dy = end_tile.y - start_tile.y
	if dx == 0:
		dx = .0001
	
	if abs(dx) >= abs(dy):
		for x in range(start_tile.x, end_tile.x+1) if start_tile.x < end_tile.x else range(end_tile.x, start_tile.x+1):
			var y = round(start_tile.y + dy * (x - start_tile.x) / dx)
			tiles.append(Vector2(x,y))
	else:
		for y in range(start_tile.y, end_tile.y+1) if start_tile.y < end_tile.y else range(end_tile.y, start_tile.y+1):
			var x = round(start_tile.x + dx * (y - start_tile.y) / dy)
			tiles.append(Vector2(x,y))
	
	return tiles
	


### LAYERS ###

func setup_layers():
	var layer_index = 0
	for l in w.current_level.get_node("Tiles").get_children():
		layers[l.name] = l
		
		var layer_node = LAYER.instance()
		layer_node.layer = l
		layer_node.connect("layer_changed", self, "change_layer")
		if layer_index == 0:
			layer_node.active = true
			tilemap = l
		get_node(layer_list).add_child(layer_node)
		layer_index += 1

func change_layer(layer):
	tilemap = layer
	for e in get_node(layer_list).get_children():
		if e.layer == layer:
			e.activate()

func get_auto_layer() -> Node:
	var layer
	var tile_pos = tileset.tile_get_region(active_tile).position
	
	match int(floor(tile_pos.y /16 / 4)):
		0: layer = layers["FarBack"]
		1: layer = layers["Back"]
		2: layer = layers["Front"]
		3: layer = layers["FarFront"]
		_: layer = layers["Front"]
	print(layer.name)
	return layer

### MISC ###

func _on_viewport_size_changed():
	rect_size = get_tree().get_root().size / w.get_node("EditorLayer").scale
	pass


func _on_TileSetMenu_tile_selection_updated(selected_tiles):
	active_tile = selected_tiles.front().front()
	if auto_layer:
		change_layer(get_auto_layer())

func _on_TileSetMenu_autolayer_updated(is_autolayer):
	auto_layer = is_autolayer


func _on_TileSetMenu_multi_erase_toggled(toggle):
	multi_erase = toggle


func _on_TileSet_collision_updated(tile_id, shape):
	var transform = Transform2D.IDENTITY
	tileset.tile_add_shape(tile_id, shape, transform)
	tileset.tile_set_shape(tile_id, 0, shape)

func _on_TileSet_tile_set_saved(path):
	ResourceSaver.save(path, tileset)

func _on_TileSet_tile_set_loaded(path):
	load_tileset(path)

func _on_TileSet_image_loaded(path):
	create_tileset_from_texture(load(path))
