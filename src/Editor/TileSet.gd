extends Control

#TODO: remove redundancies between this and TILES. there should be a master for both of them


#signal collision_updated(tile_id, shape) #moved to internal
#signal image_loaded(path)

var tx_col_brush = preload("res://assets/Editor/CollisionBrushes.png")
var tile_set_remap_true = load("res://assets/Editor/TileSetRemapTrue.png")
var tile_set_remap_false = load("res://assets/Editor/TileSetRemapFalse.png")
var tile_set_swap_true = load("res://assets/Editor/TileSetSwapTrue.png")
var tile_set_swap_false = load("res://assets/Editor/TileSetSwapFalse.png")

var current_frame = 0

var active_tab = "normal"
var active_button: Object

var texture
var columns
var rows

var hovered_button
#var selected_tile_region = Vector2.ZERO #Top Left ID, Bottom Right ID
#var selected_tiles = []
var active_normal_mode = "remap"
var active_col_brush: int


var brush_flip_h = false
var brush_flip_v = false
var brush_rotation_degrees = 0
var brush_one_way = false

@export var normal_buttons: NodePath
@export var collision_buttons: NodePath
@export var normal_cursor: NodePath
@export var brushes: NodePath

@onready var remap_button = $VBox/Margin/Tab/Normal/HBox/Remap
@onready var swap_button = $VBox/Margin/Tab/Normal/HBox/Swap
@onready var w = get_tree().get_root().get_node("World")
@onready var editor = get_parent().get_parent().get_parent().get_parent()
@onready var tile_master = editor.get_node("TileMaster")


### SETUP

func setup_tile_set():
	editor.connect("tab_changed", Callable(self, "on_tab_changed"))
	tile_master.setup_tile_buttons(self, normal_buttons)
	tile_master.setup_tile_buttons(self, collision_buttons)



func setup_brushes():
	for c in get_node(brushes).get_children():
		c.free()
	
	var brush_count = int(tx_col_brush.get_size().x / 16)
	var brush_id = 0
	for i in brush_count:
		var button = TextureButton.new()
		
		var tx_normal = AtlasTexture.new()
		tx_normal.atlas = tx_col_brush
		tx_normal.region = Rect2(brush_id * 16, 0, 16, 16)
		var tx_pressed = AtlasTexture.new()
		tx_pressed.atlas = tx_col_brush
		tx_pressed.region = Rect2(brush_id * 16, 16, 16, 16)
		
		button.texture_normal = tx_normal
		button.texture_pressed = tx_pressed
		button.rotation = brush_rotation_degrees
		button.flip_h = brush_flip_h
		button.flip_v = brush_flip_v
		
		
		button.toggle_mode = true
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.connect("pressed", Callable(self, "on_brush_selected").bind(i))
		get_node(brushes).add_child(button)
		if brush_id == 0:
			button.button_pressed = true
		brush_id += 1


### SELECTING

func hover_button(button):
	if mc.current_cursor == "arrow":
		mc.display("grabopen")
	hovered_button = button
func unhover():
	mc.display("arrow")
	hovered_button = null

func _input(event):
	if not hovered_button: return
	match active_tab:
		"normal":
			if event.is_action_pressed("editor_lmb"):
				mc.display("grabclosed")
				select_button(hovered_button)
			
			if event.is_action_released("editor_lmb") and hovered_button:
				if hovered_button != active_button:
					mc.display("grabopen")
					if active_normal_mode == "remap":
						remap_tiles(active_button, hovered_button)
					elif active_normal_mode == "swap":
						var first_pos = Vector2i(active_button.tile_set_position / 16.0)
						var second_pos = Vector2i(hovered_button.tile_set_position / 16.0)
						swap_tiles(first_pos, second_pos)
					
		#"collision":
			#if event.is_action_pressed("editor_lmb"):
				#set_collision(hovered_button)
			#if event.is_action_pressed("editor_rmb"):
				#erase_collision(hovered_button)


func select_button(button: Object):
	active_button = button
	var tile_region = Rect2(button.tile_set_position, Vector2(16, 16))
	set_cursor(tile_region)




func remap_tiles(first: Object, second: Object):
	var first_pos = Vector2i(first.tile_set_position / 16.0)
	var second_pos = Vector2i(second.tile_set_position / 16.0)
	swap_tiles(first_pos, second_pos)
	swap_tileset_coordinates(first_pos, second_pos)
	swap_tileset_pixels(first_pos, second_pos)
	active_button = second




func swap_tiles(first_pos, second_pos): #warning, this is sensative to tile_set source id #. all sources should have ids going from 0-x
	var main_tile_set = w.current_level.get_node("TileMap").tile_set
#1 create a list of all tilemaps that use this tileset
	var levels = []
	var dir = DirAccess.open("res://src/Level/")
	if dir: 
		var files = dir.get_files()
		for f in files:
			if f.get_extension() == "tscn":
				levels.append(f)
	else: printerr("ERROR: Could not load directory: res://src/Level/")
#2 create a list of all cells that use first and second tiles
	for l in levels:
		var level_path = ("res://src/Level/" + l)
		var first_cell_positions = []
		var second_cell_positions = []
		var loaded_level = w.current_level if level_path == w.current_level.scene_file_path else load(level_path).instantiate()
		var tile_map = loaded_level.get_node("TileMap")
		if tile_map.tile_set == main_tile_set:
			for layer in 4:
				first_cell_positions.append_array(tile_map.get_used_cells_by_id(layer, -1, first_pos))
				second_cell_positions.append_array(tile_map.get_used_cells_by_id(layer, -1, second_pos))
#3 set the list of cells to the reverse tile
			var first_tile_map_layer = get_tile_map_layer(first_pos.y)
			var second_tile_map_layer = get_tile_map_layer(second_pos.y)
			for cell in first_cell_positions:
				tile_map.set_cell(first_tile_map_layer, cell, -1) #erase
				tile_map.set_cell(second_tile_map_layer, cell, 0, second_pos)
			for cell in second_cell_positions:
				if !first_cell_positions.has(cell):
					tile_map.set_cell(second_tile_map_layer, cell, -1) #erase
				tile_map.set_cell(first_tile_map_layer, cell, 0, first_pos)
#4 save level
			var packed_scene = PackedScene.new()
			packed_scene.pack(loaded_level)
			var err = ResourceSaver.save(packed_scene, "res://src/Level/" + l)


func swap_tileset_coordinates(first_pos, second_pos):
	var main_tile_set = w.current_level.get_node("TileMap").tile_set
	var animation_frames = main_tile_set.get_source_count()
	for f in animation_frames:
		var atlas_source = main_tile_set.get_source(f)
		if main_tile_set.get_source(f).has_tile(first_pos):
			if main_tile_set.get_source(f).has_room_for_tile(second_pos, Vector2i.ONE, 0, Vector2i.ZERO, 1): #swap first with blank tile
				main_tile_set.get_source(f).move_tile_in_atlas(first_pos, second_pos)
			else: #swap first with filled tile
				var buffer_pos: Vector2i #first empty tile
				var source_size = main_tile_set.get_source(f).texture_region_size / 16.0
				for column in source_size.x:
					for row in column:
						if main_tile_set.get_source(f).get_tile_at_coords(Vector2i(column, row)) == -1:
							buffer_pos = Vector2i(column, row)
							break
				main_tile_set.get_source(f).move_tile_in_atlas(first_pos, buffer_pos)
				main_tile_set.get_source(f).move_tile_in_atlas(second_pos, first_pos)
				main_tile_set.get_source(f).move_tile_in_atlas(buffer_pos, second_pos)
	var err = ResourceSaver.save(main_tile_set, "res://src/Tile/Wastes.tres")


func swap_tileset_pixels(first_pos, second_pos):
	var main_tile_set = w.current_level.get_node("TileMap").tile_set
	var animation_frames = main_tile_set.get_source_count()
	for f in animation_frames:
		var first_pixels = get_tile_as_pixels(first_pos, f)
		var second_pixels = get_tile_as_pixels(second_pos, f)
		set_pixels(first_pos, second_pixels, f)
		set_pixels(second_pos, first_pixels, f)
		var texture = main_tile_set.get_source(f).texture
		var path = texture.get_path()
		var image = texture.get_image()
		image.save_png(path)
		w.current_level.get_node("TileMap").tile_set.get_source(f).set_texture(load(path))


func get_tile_as_pixels(tile_pos: Vector2i, source: int) -> Array: #2d
	var texture = w.current_level.get_node("TileMap").tile_set.get_source(source).texture
	var image = texture.get_image()
	var tile = []
	var r_id = tile_pos.y * 16
	for r in 16:
		var row = []
		var p_id = tile_pos.x * 16
		for p in 16:
			var pixel = image.get_pixel(p_id, r_id)
			row.append(pixel)
			p_id += 1
		tile.append(row)
		r_id += 1
	return tile


func set_pixels(tile_pos: Vector2i, pixels: Array, source: int):
	var texture = w.current_level.get_node("TileMap").tile_set.get_source(source).texture
	var image = texture.get_image()
	var r_id = tile_pos.y * 16
	for r in pixels:
		var p_id = tile_pos.x * 16
		for p in r:
			image.set_pixel(p_id, r_id, p)
			p_id += 1
		r_id += 1
	RenderingServer.texture_2d_update(texture.get_rid(), image, 0)



func set_cursor(region: Rect2):
	var x_pos = region.position.x + (floor(region.position.x / 16) * tile_master.tile_separation)
	var y_pos = region.position.y + (floor(region.position.y / 16) * tile_master.tile_separation)
	get_node(normal_cursor).position = Vector2(x_pos, y_pos) 
#	get_node(collision_cursor).rect_position = Vector2(x_pos, y_pos) 
	var x_size = region.size.x + (floor(region.size.x / 16) * tile_master.tile_separation)
	var y_size = region.size.y + (floor(region.size.y / 16) * tile_master.tile_separation)
	get_node(normal_cursor).size = Vector2(x_size, y_size) 
#	get_node(collision_cursor).rect_size = Vector2(x_size, y_size) 


### MISC ###
func next_animation_frame(): #pack it up and replace with sprite sheet
	var tile_map = w.current_level.get_node("TileMap")
	if !tile_map.tile_set.has_source(1):
		return
	var max_frame = tile_map.tile_set.get_source_count() - 1
	if current_frame == max_frame: current_frame = 0
	else: current_frame += 1

	var used_cells = []
	for layer in 4:
		for used_cell_pos in tile_map.get_used_cells(layer):
			var atlas_coords = tile_map.get_cell_atlas_coords(layer, used_cell_pos)
			var is_animated = tile_map.tile_set.get_source(1).has_tile(atlas_coords) #check for a second frame
			var has_next_frame = tile_map.tile_set.get_source(current_frame).has_tile(atlas_coords) #check for next frame
			if is_animated and has_next_frame:
				tile_map.set_cell(layer, used_cell_pos, current_frame, atlas_coords)
			elif is_animated:
				tile_map.set_cell(layer, used_cell_pos, 0, atlas_coords)

#
#### COLLISION
#
#func on_brush_selected(brush):
	#for c in get_node(brushes).get_children():
		#if c.get_index() != brush:
			#c.button_pressed = false
		#else:
			#c.button_pressed = true
			#active_col_brush = c.get_index()
#
#var collision_dict = {
	#"square": [Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)],
	#"slab": [Vector2(0, 8), Vector2(16, 8), Vector2(16, 16), Vector2(0, 16)],
	#"side_slab": [Vector2(8, 0), Vector2(16, 0), Vector2(16, 16), Vector2(8, 16)],
	#"slope": [Vector2(0, 16), Vector2(16, 0), Vector2(16, 16)],
	#"half_slope_a": [Vector2(0, 16), Vector2(16, 8), Vector2(16, 16)],
	#"half_slope_b": [Vector2(0, 8), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)],
#}
#
#
#func set_collision_icons():
	#var tiles = []
	#for r in get_node(collision_buttons).get_children():
		##for t in r: #TODO: check, not sure but 4.1 changed this
		#tiles.append(r)
	#
	#for t in tiles:
		#for i in t.get_children():
			#i.free()
#
		#var sprite = Sprite2D.new()
		#var texture = AtlasTexture.new()
		#texture.atlas = tx_col_brush
		#texture.region = Rect2(active_col_brush * 16, 32, 16, 16)
		#sprite.centered = false
		#sprite.texture = texture
		#
##
##		var collision = tile_set.tile_get_shape(c.id, 0)
##		match Array(collision.shape.points): #turn into array so point order does not matter, sort pls
##			collision_dict["square"]: pass
##			collision_dict["half"]:
##			collision_dict["slope"]:
##			collision_dict["half_slope_a"]:
##			collision_dict["half_slope_b"]:
#
#
#func set_collision(tile: int):
	#var tile_button
	#for r in get_node(collision_buttons).get_children():
		#for t in r.get_children():
			#if t.id == tile:
				#tile_button = t
	#for c in tile_button.get_children():
		#c.free()
			#
	#var sprite = Sprite2D.new()
	#var texture = AtlasTexture.new()
	#texture.atlas = tx_col_brush
	#texture.region = Rect2(active_col_brush * 16, 32, 16, 16)
	#sprite.centered = false
	#sprite.texture = texture
	#sprite.flip_h = brush_flip_h
	#sprite.flip_v = brush_flip_v
	#tile_button.add_child(sprite)
#
#
	#var shape = ConvexPolygonShape2D.new()
	#var points = []
	#match active_col_brush:
		#0: points = collision_dict["square"] 
		#1: points = collision_dict["half"]
		#2: points = collision_dict["slope"]
		#3: points = collision_dict["half_slope_a"]
		#4: points = collision_dict["half_slope_b"]
		#_: points = [Vector2.ZERO]
	#
	#var transformed = []
	#for p in points:
		#var x = 16 - p.x if brush_flip_h else p.x
		#var y = 16 - p.y if brush_flip_v else p.y
		#transformed.append(Vector2(x, y))
		#
	#shape.points = PackedVector2Array(transformed)
#
	##emit_signal("collision_updated", tile, shape)
	#var transform = Transform2D.IDENTITY
	#w.current_level.get_node("TileMap").tile_set.tile_add_shape(tile, shape, transform)
	#w.current_level.get_node("TileMap").tile_set.tile_set_shape(tile, 0, shape)
#
#
#
#
#func erase_collision(tile: int):
	#var tile_button
	#for r in get_node(collision_buttons).get_children():
		#for t in r.get_children():
			#if t.id == tile:
				#tile_button = t
	#for c in tile_button.get_children():
		#c.free()



### HELPER GETTERS ###

func get_tile_map_layer(y_pos: int) -> int:
	var tile_map_layer = 0
	match y_pos:
		0, 1, 2, 3: #FarBack
			tile_map_layer = 0
		4, 5, 6, 7: #Back
			tile_map_layer = 1
		8, 9, 10, 11: #Front
			tile_map_layer = 2
		12, 13, 14, 15: #FarFront
			tile_map_layer = 3
		_:
			printerr("ERROR: Tile position is too large in y-axis to accurately determine its tile map layer, defaulting to 0")
	return tile_map_layer



### SIGNALS ###

func _on_Save_pressed():
	$Save.current_path = "res://src/Tile/"
	$Save.popup()
func _on_Load_pressed():
	$Load.current_path = "res://src/Tile/"
	$Load.popup()
func _on_New_pressed():
	$New.current_path = "res://assets/Tile/"
	$New.popup()

func _on_Save_confirmed():
	var path = $Save.current_path
	var err = ResourceSaver.save(path.get_basename() + ".tres", editor.tile_set)
	if err == OK:
		print("tile set saved")
	else:
		printerr("ERROR: tile set not saved!")
	load_tile_set(path)
	
	
func _on_Load_file_selected(path):
	load_tile_set(path)

func load_tile_set(path):
	w.current_level.get_node("TileMap").tile_set = load(path)
	editor.get_node("Main/Win/Tab/Tiles").setup_tiles()
	setup_tile_set()


#func _on_Reload_pressed():
#	var texture = tile_set.tile_get_texture(tile_set.get_tiles_ids().front())
#	var image = texture.get_data()
#	VisualServer.texture_set_data(texture.get_rid(), image)

func _on_New_file_selected(path):
	var tile_set = TileSet.new()
	texture = load(path)
	rows = int(texture.get_size().y/16)
	var columns = int(texture.get_size().x/16)

	var id = 0
	while id < rows * columns:
		var x_pos = (id % columns) * 16
		var y_pos = floor(id / columns) * 16
		var region = Rect2(x_pos, y_pos, 16, 16)
		tile_set.create_tile(id)
		tile_set.tile_set_texture(id, texture)
		tile_set.tile_set_region(id, region)
		id += 1
	
	load_tile_set(path)



func on_tab_changed(tab_name):
	pass

func _on_subtab_changed(tab):
	match tab:
		0: active_tab = "normal"
		1: active_tab = "collision"

func _on_OneWay_toggled(button_pressed):
	brush_one_way = button_pressed
	setup_brushes()

func _on_FlipV_toggled(button_pressed):
	brush_flip_v = button_pressed
	setup_brushes()

func _on_FlipH_toggled(button_pressed):
	brush_flip_h = button_pressed
	setup_brushes()

func _on_RotateC_toggled(button_pressed):
	if brush_rotation_degrees == 270:
		brush_rotation_degrees = 0
	else:
		brush_rotation_degrees += 90
	setup_brushes()

func _on_RotateCC_toggled(button_pressed):
	if brush_rotation_degrees == 0:
		brush_rotation_degrees = 270
	else:
		brush_rotation_degrees -= 90
	setup_brushes()


func _on_Remap_pressed():
	$VBox/Margin/Tab/Normal/HBox/Swap.button_pressed = false
	active_normal_mode = "remap"
	remap_button.icon = tile_set_remap_true
	swap_button.icon = tile_set_swap_false

func _on_Swap_toggled(toggled_on):
	$VBox/Margin/Tab/Normal/HBox/Remap.button_pressed = false
	active_normal_mode = "swap"
	remap_button.icon = tile_set_remap_false
	swap_button.icon = tile_set_swap_true




func _on_Animation_toggled(toggled_on):
	next_animation_frame()
