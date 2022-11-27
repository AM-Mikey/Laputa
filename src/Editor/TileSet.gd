extends Control

signal collision_updated(tile_id, shape)
signal tile_set_saved(path)
signal tile_set_loaded(path)
signal image_loaded(path)

var tx_col_brush = preload("res://assets/Editor/CollisionBrushes.png")

var active_tab = "normal"
var active_tile: int

var tile_set
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


export var tile_separation: int = 1
export(NodePath) var normal_buttons
export(NodePath) var collision_buttons
export(NodePath) var normal_cursor
#export(NodePath) var collision_cursor
export(NodePath) var brushes



func _ready():
	setup_brushes()

### SETUP

func setup_tile_set(new):
	tile_set = new
	texture = tile_set.tile_get_texture(0)
	columns = int(texture.get_size().x/16)
	rows = int(texture.get_size().y/16)
	
	setup_tile_buttons(normal_buttons)
	setup_tile_buttons(collision_buttons)

func setup_tile_buttons(parent):
	for c in get_node(parent).get_children(): #clear old rows
		c.free()
###
	get_node(parent).add_constant_override("separation", tile_separation)
	var r_id = 0
	for r in rows:
		var row = HBoxContainer.new()
		row.add_constant_override("separation", tile_separation)
		#row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_node(parent).add_child(row)
		var c_id = 0
		for c in columns:
			var button = load("res://src/Editor/Button/TileButton.tscn").instance()
			button.tile_set_position = Vector2(c_id*16, r_id*16) 
			row.add_child(button)
			button.connect("mouse_entered", self, "hover_button", [button])
			button.connect("mouse_exited", self, "unhover")
			c_id += 1
		r_id += 1
###
	for i in tile_set.get_tiles_ids():
		var x_pos: int = floor(tile_set.tile_get_region(i).position.x/16)
		var y_pos: int = floor(tile_set.tile_get_region(i).position.y/16)
		var button = get_node(parent).get_child(y_pos).get_child(x_pos)
		button.id = i
		button.texture = get_tile_as_texture(i)


func get_tile_as_texture(id) -> Texture:
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = texture
	tile_texture.region = tile_set.tile_get_region(id)
	return tile_texture

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
		button.rect_rotation = brush_rotation_degrees
		button.flip_h = brush_flip_h
		button.flip_v = brush_flip_v
		
		
		button.toggle_mode = true
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.connect("pressed", self, "on_brush_selected", [i])
		get_node(brushes).add_child(button)
		if brush_id == 0:
			button.pressed = true
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
	var tile_region = tile_set.tile_get_region(tile)
	set_cursor(tile_region)


func swap_tile(first: int, second: int): #repalces tile mapping without graphics
	var first_region = tile_set.tile_get_region(first)
	var second_region = tile_set.tile_get_region(second)
	tile_set.tile_set_region(first, second_region)
	tile_set.tile_set_region(second, first_region)

func move_tile(first: int, second: int):
	var first_region = tile_set.tile_get_region(first)
	var second_region = tile_set.tile_get_region(second)
	var first_pixels = get_tile_as_pixels(first_region)
	var second_pixels = get_tile_as_pixels(second_region)
	set_pixels(first_region, second_pixels)
	set_pixels(second_region, first_pixels)
	tile_set.tile_set_region(first, second_region)
	tile_set.tile_set_region(second, first_region)
	
	var texture = tile_set.tile_get_texture(tile_set.get_tiles_ids().front())
	var path = texture.get_path()
	var image = texture.get_data()
	
	image.save_png(path)
	emit_signal("tile_set_saved", tile_set.get_path())
	emit_signal("tile_set_loaded", tile_set.get_path())
	active_tile = second


func get_tile_region(id):
	tile_set.tile_get_region(id)


func get_tile_as_pixels(region: Rect2) -> Array: #2d
	var texture = tile_set.tile_get_texture(tile_set.get_tiles_ids().front())
	var image = texture.get_data()
	
	image.lock()
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
	
	image.unlock()
	return tile

func set_pixels(region: Rect2, pixels: Array):
	#print("setting pixels in region: " + String(region))
	var texture = tile_set.tile_get_texture(tile_set.get_tiles_ids().front())
	var image = texture.get_data()
	
	image.lock()

	var r_id = region.position.y
	for r in pixels:
		var p_id = region.position.x
		for p in r:
			image.set_pixel(p_id, r_id, p)
			p_id += 1
		r_id += 1
	
	image.unlock()
	VisualServer.texture_set_data(texture.get_rid(), image)




func set_cursor(region: Rect2):
	var x_pos = region.position.x + (floor(region.position.x / 16) * tile_separation)
	var y_pos = region.position.y + (floor(region.position.y / 16) * tile_separation)
	get_node(normal_cursor).rect_position = Vector2(x_pos, y_pos) 
#	get_node(collision_cursor).rect_position = Vector2(x_pos, y_pos) 
	var x_size = region.size.x + (floor(region.size.x / 16) * tile_separation)
	var y_size = region.size.y + (floor(region.size.y / 16) * tile_separation)
	get_node(normal_cursor).rect_size = Vector2(x_size, y_size) 
#	get_node(collision_cursor).rect_size = Vector2(x_size, y_size) 






### COLLISION

func on_brush_selected(brush):
	for c in get_node(brushes).get_children():
		if c.get_index() != brush:
			c.pressed = false
		else:
			c.pressed = true
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
		for t in r:
			tiles.append(t)
	
	for t in tiles:
		for i in t.get_children():
			i.free()

		var sprite = Sprite.new()
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
			
	var sprite = Sprite.new()
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
		
	shape.points = PoolVector2Array(transformed)

	emit_signal("collision_updated", tile, shape)




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
	emit_signal("tile_set_saved", path.get_basename() + ".tres")
	
func _on_Load_file_selected(path):
	emit_signal("tile_set_loaded", path)

func _on_Reload_pressed():
	emit_signal("tile_set_loaded", tile_set.get_path())
	var texture = tile_set.tile_get_texture(tile_set.get_tiles_ids().front())
	var image = texture.get_data()
	VisualServer.texture_set_data(texture.get_rid(), image)

func _on_New_file_selected(path):
	emit_signal("image_loaded", path)


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



