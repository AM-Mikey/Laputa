extends Control

const LAYER_BUTTON = preload("res://src/Editor/LayerButton.tscn")
const LIMITER = preload("res://src/Editor/EditorLevelLimiter.tscn")



export(NodePath) var tiles_tab
export(NodePath) var layer_list


var active_tiles = [] #2D array

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
	load_tileset(tile_collection.get_child(0).tile_set.resource_path)
	setup_level_limiter()
	setup_layers()
	#$Main.move_child($Main/Tab, 0) TODO: was supposed to make tabcontainer go behind resize controls, didnt work


func setup_level_limiter():
	#w.get_node("EditorLayer").add_child(LIMITER.instance())
	w.current_level.add_child(LIMITER.instance())

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



func get_tile_texture(tile):
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = tileset.tile_get_texture(tile)
	tile_texture.region = tileset.tile_get_region(tile)
	return tile_texture




func _unhandled_input(event):
	var mouse_pos = w.get_global_mouse_position()
	
	if event.is_action_pressed("editor_lmb") and not active_tiles.empty():
		lmb_held = true
		future_operations.clear()
		mouse_start_pos = mouse_pos
		
		if shift_held:
			brush = "line"
		elif ctrl_held:
			brush = "box"
		else:
			brush = "paint"
			set_2d_array(get_centerbox(mouse_pos), active_tiles)


	if event.is_action_released("editor_lmb"):
		lmb_held = false
		if brush == "line":
			set_line(get_brush_origin_line(mouse_start_pos, mouse_pos), active_tiles)
		elif brush == "box":
			set_2d_array(get_box(mouse_start_pos, mouse_pos), active_tiles)
		
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
#			if multi_erase: #TODO: does not work
#				set_tiles_on_all_layers([get_cell(mouse_pos)], -1) 
#			else:
			set_2d_array(get_centerbox(mouse_pos), get_brush_as_eraser())


	if event.is_action_released("editor_rmb"):
		rmb_held = false
		if brush == "line":
			set_2d_array(get_brush_line(mouse_start_pos, mouse_pos), get_brush_as_eraser())
		elif brush == "box":
			set_2d_array(get_box(mouse_start_pos, mouse_pos), get_brush_as_eraser())
		
		if not active_operation.empty():
			var operation_name = "set_tiles_on_all_layers" if multi_erase else "set_tiles"
			past_operations.append([operation_name, active_operation.duplicate()])
			#print("active op: ", active_operation)
			active_operation.clear()




	if event is InputEventMouseMotion:
		if lmb_held and brush == "paint":
			#set_tiles([get_cell(mouse_pos)], active_tiles)
			set_2d_array(get_centerbox(mouse_pos), active_tiles)
		if rmb_held and brush == "paint":
#			if multi_erase: #TODO: not working
#				set_cells_on_all_layers([get_cell(mouse_pos)], -1)
#			else:
#				#set_tiles([get_cell(mouse_pos)], -1)
				set_2d_array(get_centerbox(mouse_pos), get_brush_as_eraser())

		hide_preview()
		if brush == "paint":
			preview_2d_array(get_centerbox(mouse_pos))
			#preview_tiles([get_cell(mouse_pos)])

		elif lmb_held or rmb_held:
			if brush == "line":
				preview_line(get_brush_origin_line(mouse_start_pos, mouse_pos))
			if brush == "box":
				preview_2d_array(get_box(mouse_start_pos, mouse_pos))




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
				var subops = last[1]
				subops.invert()
				for t in subops:
					set_cells([t[0]], t[2], false) #pos_array, old_tile, traced
#	else:
#		print("nothing left to undo!")


func redo():
	var next = future_operations.pop_back()
	
	if next:
		past_operations.append(next)
		print("redoing operation: ", next)
		
		match next[0]:
			"set_tiles":
				var subops = next[1]
				subops.invert()
				for t in subops:
					set_cells([t[0]], t[1], false) #pos_array, new_tile, traced
#	else:
#		print("nothing left to redo!")



func set_cells(cells: Array, tile, traced = true): #TODO, new draw methods use set 2d array instead, this can only handle one tile
	if tile == -2: #null
		return
	for cell in cells: #subops
		var old_tile = tilemap.get_cellv(cell)
		tilemap.set_cellv(cell, tile)
		if traced:
			for s in active_operation:
				if s[0] == cell: #already setting this cell in the current operation, this prevents reactivating on mouse movement
					return
			active_operation.append([cell, tile, old_tile])

func set_2d_array(cells: Array, tiles: Array, traced = true):
	if tiles.empty():
		return
	var r_id = 0
	var r_max = tiles.size()
	for row in cells:
		var c_id = 0
		var c_max = tiles[c_id].size()
		for cell in row: #subops
			var tile = tiles[r_id % r_max][c_id % c_max] # % so it repeats if cells > tiles
			if tile != -2: #null
				var old_tile = tilemap.get_cellv(cell)
				tilemap.set_cellv(cell, tile)
				
				if traced:
					for s in active_operation:
						if s[0] == cell and s[1] == tile: #already setting this cell in the current operation, this prevents reactivating on mouse movement
							return
					active_operation.append([cell, tile, old_tile])

			c_id += 1
		r_id += 1

func set_line(cells: Array, tiles: Array, traced = true):
	if tiles.empty():
		return
	var r_id = 0
	var r_max = tiles.size()
	for row in cells:
		var c_id = 0
		var c_max = tiles[c_id].size()
		for cell in row: #subops
			var br_id = 0
			for b_row in active_tiles:
				var bc_id = 0
				for b_cell in b_row:
					var tile = b_cell
					if tile != -2: #null
						var offset = Vector2(bc_id, br_id)
						var old_tile = tilemap.get_cellv(cell + offset)
						tilemap.set_cellv(cell + offset, tile)
						
						if traced:
							for s in active_operation:
								if s[0] == cell and s[1] == tile: #already setting this cell in the current operation, this prevents reactivating on mouse movement
									return
							active_operation.append([cell + offset, tile, old_tile])
					
					bc_id += 1
				br_id +=1
			c_id += 1
		r_id += 1



func set_cells_on_all_layers(pos_array: Array, tile, traced = true): #TODO: finish this as it doesnt work right now
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

func preview_2d_array(cells: Array):
	var r_id = 0
	var r_max = active_tiles.size()
	for row in cells:
		var c_id = 0
		var c_max = active_tiles[c_id].size()
		for cell in row:
			var tile = active_tiles[r_id % r_max][c_id % c_max] # % so it repeats if cells > tiles
			set_preview(cell, tile)
			c_id += 1
		r_id += 1

func preview_line(cells: Array): #use get_brush_origin for this
	var r_id = 0
	var r_max = active_tiles.size()
	for row in cells:
		var c_id = 0
		var c_max = active_tiles[c_id].size()
		for cell in row:
			
			var br_id = 0
			for b_row in active_tiles:
				var bc_id = 0
				for b_cell in b_row:
					var tile = b_cell
					var offset = Vector2(bc_id, br_id)
					set_preview(cell + offset, tile)
					bc_id += 1
				br_id +=1
			c_id += 1
		r_id += 1

func set_preview(cell, tile):
	if tile == -2: #null
		return
		
	var sprite = Sprite.new()
	sprite.texture = get_tile_texture(tile)
	sprite.modulate = Color(1, 1, 1, 0.5)
	sprite.centered = false
	sprite.position = cell * 16
	tile_collection.add_child(sprite)

func hide_preview():
	for c in tile_collection.get_children():
		if c is Sprite:
			c.queue_free()



### GETTERS ###
func get_cell(mouse_pos) -> Vector2:
	var local_pos = tilemap.to_local(mouse_pos)
	var map_pos = tilemap.world_to_map(local_pos)
	return map_pos


func get_centerbox(mouse_pos) -> Array: #2D Array #actuve tiles
	var cells = []
	var bx = get_brush_size("x")
	var by = get_brush_size("y")
	
	var center = Vector2(floor(bx/2), floor(by/2))
	var center_cell = get_cell(mouse_pos)
	#assumes an odd number
	for row in by:
		var row_cells = []
		for cell in bx:
			var offset = Vector2(cell - center.x, row - center.y)
			row_cells.append(center_cell + offset) #position of cell in map space
		if not row_cells.empty():
			cells.append(row_cells)
	
	#print(cells)
	return cells



func get_box(start_pos, end_pos) -> Array: #2d
	var cells = []
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var x_min = min(start.x, end.x)
	var x_max = max(start.x, end.x)
	var y_min = min(start.y, end.y)
	var y_max = max(start.y, end.y)
	
	for y in range(y_min, y_max + 1):
		var row = []
		for x in range(x_min, x_max + 1):
			row.append(Vector2(x, y))
		cells.append(row)
	return cells

#func get_line(start_pos, end_pos) -> Array: #2d
#	var cells = [] #1d
#	var start = get_cell(start_pos)
#	var end = get_cell(end_pos)
#	var x_min = min(start.x, end.x)
#	var x_max = max(start.x, end.x)
#	var y_min = min(start.y, end.y)
#	var y_max = max(start.y, end.y)
#	var dx = end.x - start.x
#	var dy = end.y - start.y
#	if dx == 0:
#		dx = .0001
#
#	var fake_cells = []
#	if abs(dx) >= abs(dy):
#		for x in range(x_min, x_max+1):
#			var y = round(start.y + dy * (x - start.x) / dx)
#			cells.append(Vector2(x,y))
#	else:
#		for y in range(y_min, y_max+1):
#			var x = round(start.x + dx * (y - start.y) / dy)
#			cells.append(Vector2(x,y))
#	return get_2d_array_from_Vector2_array(cells)

func get_brush_line(start_pos, end_pos) -> Array: #2d
	var cells = []
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var x_min = min(start.x, end.x)
	var x_max = max(start.x, end.x)
	var y_min = min(start.y, end.y)
	var y_max = max(start.y, end.y)
	var dx = end.x - start.x
	var dy = end.y - start.y
	if dx == 0:
		dx = .0001
	var bx = get_brush_size("x")
	var by = get_brush_size("y")

	if abs(dx) >= (float(bx)/float(by)) * abs(dy): #TODO: this division seems to slow down the game with very tall brushes
		for x in range(x_min, x_max+1):
			if x % bx == 0: #start of a brush 
				var y = round(start.y + dy * (x - start.x) / dx)

				for row in by:
					for cell in bx:
						cells.append(Vector2(x + cell, y + row))

	else:
		for y in range(y_min, y_max+1):
			if y % by == 0: #start of a brush 
				var x = round(start.x + dx * (y - start.y) / dy)

				for row in by:
					for cell in bx:
						cells.append(Vector2(x + cell, y + row))

	#print("cells: ",get_2d_array_from_Vector2_array(cells))
	return get_2d_array_from_Vector2_array(cells)

func get_brush_origin_line(start_pos, end_pos) -> Array: #2d, only origin points of brushes
	var cells = []
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var x_min = min(start.x, end.x)
	var x_max = max(start.x, end.x)
	var y_min = min(start.y, end.y)
	var y_max = max(start.y, end.y)
	var dx = end.x - start.x
	var dy = end.y - start.y
	if dx == 0:
		dx = .0001
	var bx = get_brush_size("x")
	var by = get_brush_size("y")
	
	if abs(dx) >= (float(bx)/float(by)) * abs(dy): #TODO: this division seems to slow down the game with very tall brushes
		for x in range(x_min, x_max+1):
			if x % bx == 0: #start of a brush 
				var y = round(start.y + dy * (x - start.x) / dx)
				cells.append(Vector2(x, y))
	
	else:
		for y in range(y_min, y_max+1):
			if y % by == 0: #start of a brush 
				var x = round(start.x + dx * (y - start.y) / dy)
				cells.append(Vector2(x, y))
	
	#print("cells: ",get_2d_array_from_Vector2_array(cells))
	return get_2d_array_from_Vector2_array(cells)


func get_brush_as_eraser() -> Array:
	var eraser = []
	for row in active_tiles:
		var eraser_row = []
		for tile in row:
			eraser_row.append(-2) if tile == -2 else eraser_row.append(-1)
		eraser.append(eraser_row)
	print(eraser)
	return eraser

### HELPER GETTERS ###

func get_brush_size(axis = "both"):
	var brush_size = Vector2.ZERO
	brush_size.y = active_tiles.size()
	for row in active_tiles:
		if row.size() > brush_size.x:
			brush_size.x = row.size()
	if axis == "x":
		return int(brush_size.x)
	if axis == "y":
		return int(brush_size.y)
	else:
		return brush_size

func get_2d_array_from_Vector2_array(array) -> Array:
	var new_array = []
	var recorded_ys = []
	for i in array:
		if not recorded_ys.has(i.y):
			recorded_ys.append(i.y)
			var row = []
			row.append(i)
			new_array.append(row)
		else:
			new_array[recorded_ys.find(i.y)].append(i)
	return new_array

### LAYERS ###

func setup_layers():
	var layer_index = 0
	for l in w.current_level.get_node("Tiles").get_children():
		layers[l.name] = l
		
		var layer_button = LAYER_BUTTON.instance()
		layer_button.layer = l
		layer_button.connect("layer_changed", self, "change_layer")
		if layer_index == 0:
			layer_button.active = true
			tilemap = l
		get_node(layer_list).add_child(layer_button)
		layer_index += 1

func change_layer(layer):
	tilemap = layer
	for e in get_node(layer_list).get_children():
		if e.layer == layer:
			e.activate()

#func get_auto_layer() -> Node: TODO FIX for multibox
#	var layer
#	var tile_pos = tileset.tile_get_region(active_tile).position
#
#	match int(floor(tile_pos.y /16 / 4)):
#		0: layer = layers["FarBack"]
#		1: layer = layers["Back"]
#		2: layer = layers["Front"]
#		3: layer = layers["FarFront"]
#		_: layer = layers["Front"]
#	print(layer.name)
#	return layer

### SIGNALS ###

func _on_viewport_size_changed():
	rect_size = get_tree().get_root().size / w.get_node("EditorLayer").scale
	pass


func _on_TileSetMenu_tile_selection_updated(selected_tiles):
	active_tiles = selected_tiles
#	if auto_layer:
#		change_layer(get_auto_layer())

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
