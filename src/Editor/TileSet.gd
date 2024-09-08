extends Control

#TODO: remove redundancies between this and TILES. there should be a master for both of them


#signal collision_updated(tile_id, shape) #moved to internal
#signal tile_set_saved(path)
#signal tile_set_loaded(path)
#signal image_loaded(path)

var tx_col_brush = preload("res://assets/Editor/CollisionBrushes.png")

var active_tab = "normal"
var active_tile: int

#var tile_set
var texture
var columns
var rows

var hovered_tile
#var selected_tile_region = Vector2.ZERO #Top Left ID, Bottom Right ID
#var selected_tiles = []
var active_col_brush: int

var brush_flip_h = false
var brush_flip_v = false
var brush_rotation_degrees = 0
var brush_one_way = false


@export var normal_buttons: NodePath
@export var collision_buttons: NodePath
@export var normal_cursor: NodePath
#export(NodePath) var collision_cursor
@export var brushes: NodePath

@onready var w = get_tree().get_root().get_node("World")
@onready var editor = get_parent().get_parent().get_parent().get_parent()
@onready var tile_master = editor.get_node("TileMaster")


### SETUP

func setup_tile_set():
	
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

func hover_button(tile_button):
	hovered_tile = tile_button.id

func unhover():
	hovered_tile = null

func _input(event):
	if not hovered_tile: return
	match active_tab:
		"normal":
			if event.is_action_pressed("editor_lmb"):
				select_tile(hovered_tile)
#			if event.is_action_pressed("editor_rmb"):
#				swap_tile(active_tile, hovered_tile)
			if event.is_action_pressed("editor_mmb"):
					if active_tile:
						move_tile(active_tile, hovered_tile)
		"collision":
			if event.is_action_pressed("editor_lmb"):
				set_collision(hovered_tile)
			if event.is_action_pressed("editor_rmb"):
				erase_collision(hovered_tile)


func select_tile(tile: int):
	active_tile = tile
	var tile_region = editor.tile_set.tile_get_region(tile)
	set_cursor(tile_region)


func swap_tile(first: int, second: int): #repalces tile mapping without graphics
	var first_region = editor.tile_set.tile_get_region(first)
	var second_region = editor.tile_set.tile_get_region(second)
	editor.tile_set.tile_set_region(first, second_region)
	editor.tile_set.tile_set_region(second, first_region)

func move_tile(first: int, second: int):
	var first_region = editor.tile_set.tile_get_region(first)
	var second_region = editor.tile_set.tile_get_region(second)
	var first_pixels = get_tile_as_pixels(first_region)
	var second_pixels = get_tile_as_pixels(second_region)
	set_pixels(first_region, second_pixels)
	set_pixels(second_region, first_pixels)
	editor.tile_set.tile_set_region(first, second_region)
	editor.tile_set.tile_set_region(second, first_region)
	
	var texture = editor.tile_set.tile_get_texture(editor.tile_set.get_tiles_ids().front())
	var path = texture.get_path()
	var image = texture.get_data()
	
	image.save_png(path)
	emit_signal("tile_set_saved", editor.tile_set.get_path())
	emit_signal("tile_set_loaded", editor.tile_set.get_path())
	active_tile = second


func get_tile_region(id):
	editor.tile_set.tile_get_region(id)


func get_tile_as_pixels(region: Rect2) -> Array: #2d
	var texture = editor.tile_set.tile_get_texture(editor.tile_set.get_tiles_ids().front())
	var image = texture.get_data()
	
	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	var tile = []
	var r_id = region.position.y
	for r in region.size.y:
		var row = []
		var p_id = region.position.x
		for p in region.size.x:
			var pixel = image.get_pixel(p_id, r_id)
			row.append(pixel)
			p_id += 1
		tile.append(row)
		r_id += 1
	
	false # image.unlock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
	return tile

func set_pixels(region: Rect2, pixels: Array):
	#print("setting pixels in region: " + String(region))
	var texture = editor.tile_set.tile_get_texture(editor.tile_set.get_tiles_ids().front())
	var image = texture.get_data()
	
	false # image.lock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed

	var r_id = region.position.y
	for r in pixels:
		var p_id = region.position.x
		for p in r:
			image.set_pixel(p_id, r_id, p)
			p_id += 1
		r_id += 1
	
	false # image.unlock() # TODOConverter3To4, Image no longer requires locking, `false` helps to not break one line if/else, so it can freely be removed
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






### COLLISION

func on_brush_selected(brush):
	for c in get_node(brushes).get_children():
		if c.get_index() != brush:
			c.button_pressed = false
		else:
			c.button_pressed = true
			active_col_brush = c.get_index()

var collision_dict = {
	"square": [Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)],
	"slab": [Vector2(0, 8), Vector2(16, 8), Vector2(16, 16), Vector2(0, 16)],
	"side_slab": [Vector2(8, 0), Vector2(16, 0), Vector2(16, 16), Vector2(8, 16)],
	"slope": [Vector2(0, 16), Vector2(16, 0), Vector2(16, 16)],
	"half_slope_a": [Vector2(0, 16), Vector2(16, 8), Vector2(16, 16)],
	"half_slope_b": [Vector2(0, 8), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)],
}


func set_collision_icons():
	var tiles = []
	for r in get_node(collision_buttons).get_children():
		#for t in r: #TODO: check, not sure but 4.1 changed this
		tiles.append(r)
	
	for t in tiles:
		for i in t.get_children():
			i.free()

		var sprite = Sprite2D.new()
		var texture = AtlasTexture.new()
		texture.atlas = tx_col_brush
		texture.region = Rect2(active_col_brush * 16, 32, 16, 16)
		sprite.centered = false
		sprite.texture = texture
		
#
#		var collision = tile_set.tile_get_shape(c.id, 0)
#		match Array(collision.shape.points): #turn into array so point order does not matter, sort pls
#			collision_dict["square"]: pass
#			collision_dict["half"]:
#			collision_dict["slope"]:
#			collision_dict["half_slope_a"]:
#			collision_dict["half_slope_b"]:


func set_collision(tile: int):
	var tile_button
	for r in get_node(collision_buttons).get_children():
		for t in r.get_children():
			if t.id == tile:
				tile_button = t
	for c in tile_button.get_children():
		c.free()
			
	var sprite = Sprite2D.new()
	var texture = AtlasTexture.new()
	texture.atlas = tx_col_brush
	texture.region = Rect2(active_col_brush * 16, 32, 16, 16)
	sprite.centered = false
	sprite.texture = texture
	sprite.flip_h = brush_flip_h
	sprite.flip_v = brush_flip_v
	tile_button.add_child(sprite)


	var shape = ConvexPolygonShape2D.new()
	var points = []
	match active_col_brush:
		0: points = collision_dict["square"] 
		1: points = collision_dict["half"]
		2: points = collision_dict["slope"]
		3: points = collision_dict["half_slope_a"]
		4: points = collision_dict["half_slope_b"]
		_: points = [Vector2.ZERO]
	
	var transformed = []
	for p in points:
		var x = 16 - p.x if brush_flip_h else p.x
		var y = 16 - p.y if brush_flip_v else p.y
		transformed.append(Vector2(x, y))
		
	shape.points = PackedVector2Array(transformed)

	#emit_signal("collision_updated", tile, shape)
	var transform = Transform2D.IDENTITY
	editor.tile_set.tile_add_shape(tile, shape, transform)
	editor.tile_set.tile_set_shape(tile, 0, shape)




func erase_collision(tile: int):
	var tile_button
	for r in get_node(collision_buttons).get_children():
		for t in r.get_children():
			if t.id == tile:
				tile_button = t
	for c in tile_button.get_children():
		c.free()




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
	#emit_signal("tile_set_saved", path.get_basename() + ".tres")
	var err = ResourceSaver.save(path.get_basename() + ".tres", editor.tile_set)
	if err == OK:
		print("tile set saved")
	else:
		printerr("ERROR: tile set not saved!")
	load_tile_set(path)
	
	
func _on_Load_file_selected(path):
	#emit_signal("tile_set_loaded", path)
	load_tile_set(path)

func load_tile_set(path):
	editor.tile_set = load(path)
	
	editor.get_node("Main/Win/Tab/Tiles").setup_tiles()
	setup_tile_set()
	
	for c in editor.tile_collection.get_children():
		if c is TileMap:
			c.tile_set = editor.tile_set
	w.current_level.tile_set = editor.tile_set



#func _on_Reload_pressed():
#	emit_signal("tile_set_loaded", tile_set.get_path())
#	var texture = tile_set.tile_get_texture(tile_set.get_tiles_ids().front())
#	var image = texture.get_data()
#	VisualServer.texture_set_data(texture.get_rid(), image)

func _on_New_file_selected(path):
	#emit_signal("image_loaded", path)
	#editor.create_tile_set_from_texture(load(path))
#func create_tile_set_from_texture(texture):
	editor.tile_set = TileSet.new()
	texture = load(path)
	rows = int(texture.get_size().y/16)
	var columns = int(texture.get_size().x/16)

	var id = 0
	while id < rows * columns:
		var x_pos = (id % columns) * 16
		var y_pos = floor(id / columns) * 16
		var region = Rect2(x_pos, y_pos, 16, 16)

		editor.tile_set.create_tile(id)
		editor.tile_set.tile_set_texture(id, texture)
		editor.tile_set.tile_set_region(id, region)
		id += 1

	editor.get_node("Main/Win/Tab/Tiles").setup_tiles() #TODO: merge with save or load
	setup_tile_set()

	for c in editor.tile_collection.get_children():
		if c is TileMap:
			c.tile_set = editor.tile_set




func on_tab_changed(tab):
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
