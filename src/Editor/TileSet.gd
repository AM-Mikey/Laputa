extends Control

signal collision_updated(tile_id, shape)
signal tile_set_saved(path)
signal tile_set_loaded(path)
signal image_loaded(path)


var tx_col_brush = preload("res://assets/Editor/CollisionBrushes.png")


var tileset
var texture
var columns
var rows

var hovered_tile
#var selected_tile_region = Vector2.ZERO #Top Left ID, Bottom Right ID
#var selected_tiles = []
var active_col_brush: int

var lmb_pressed = false
var rmb_pressed = false

export(NodePath) var brushes
export(NodePath) var col_tiles

func _ready():
	setup_brushes()


func setup_tileset(new):
	tileset = new
	texture = tileset.tile_get_texture(0)
	columns = int(texture.get_size().x/16)
	rows = int(texture.get_size().y/16)
	
	setup_tile_buttons()

func setup_brushes():
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
		
		button.toggle_mode = true
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.connect("pressed", self, "on_brush_selected", [i])
		get_node(brushes).add_child(button)
		if brush_id == 0:
			button.pressed = true
		brush_id += 1

func on_brush_selected(brush):
	for c in get_node(brushes).get_children():
		if c.get_index() != brush:
			c.pressed = false
		else:
			c.pressed = true
			active_col_brush = c.get_index()
		

func setup_tile_buttons():
	var p = get_node(col_tiles)
	var r_id = 0
	for y in rows:
		var row = HBoxContainer.new()
		row.add_constant_override("separation", 1)
		p.add_child(row)
		
		var c_id = 0
		for x in columns:
			var tile = load("res://src/Editor/TileButton.tscn").instance()
			var sp_tex = AtlasTexture.new()
			sp_tex.atlas = texture
			sp_tex.region = Rect2(c_id * 16, r_id * 16, 16, 16)
			tile.id = r_id * columns + c_id
			tile.texture = sp_tex
			row.add_child(tile)
			tile.connect("mouse_entered", self, "hover_tile", [tile])
			tile.connect("mouse_exited", self, "unhover")
			c_id +=1
		
		r_id += 1
	
	
#	tileset.clear()
#
#	var id = tileset.get_last_unused_tile_id()
#	while id < rows * columns:
#		tileset.create_tile(id)
#		tileset.tile_set_texture(id, texture)
#
#		var x_pos = (id % columns) * 16
#		var y_pos = floor(id / columns) * 16
#		var region = Rect2(x_pos, y_pos, 16, 16)
#		tileset.tile_set_region(id, region)
#		id += 1

func hover_tile(tile_node):
	print("hover")
	hovered_tile = tile_node
	if lmb_pressed:
		set_collision(tile_node)
	elif rmb_pressed:
		erase_collision(tile_node)
func unhover():
	hovered_tile = null



func _input(event):
	if event is InputEventMouseMotion:
		return
	#if Input.is_action_just_pressed("editor_lmb"):
	if event.is_action_pressed("editor_lmb"):
		lmb_pressed = true
		if hovered_tile:
			set_collision(hovered_tile)
	if event.is_action_released("editor_lmb"):
		lmb_pressed = false

	if event.is_action_pressed("editor_rmb"):
		rmb_pressed = true
		if hovered_tile:
			erase_collision(hovered_tile)
	if event.is_action_released("editor_rmb"):
		rmb_pressed = false



func set_collision(tile_node):
	for c in tile_node.get_children():
		c.free()
	var sprite = Sprite.new()
	var texture = AtlasTexture.new()
	texture.atlas = tx_col_brush
	texture.region = Rect2(active_col_brush * 16, 32, 16, 16)
	sprite.centered = false
	sprite.texture = texture
	tile_node.add_child(sprite)
	

	var shape = ConvexPolygonShape2D.new()
	match active_col_brush:
		0: shape.set_points([Vector2(0, 0), Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)]) #square
		1: shape.set_points([Vector2(16, 0), Vector2(16, 16), Vector2(0, 16)]) #tri left
		2: shape.set_points([Vector2(0, 0), Vector2(16, 16), Vector2(0, 16)]) #tri right

	emit_signal("collision_updated", tile_node.id, shape)



func erase_collision(tile_node):
	for c in tile_node.get_children():
		c.free()




func _on_Save_pressed():
	$Save.popup()
func _on_Load_pressed():
	$Load.popup()
func _on_New_pressed():
	$New.popup()


func _on_Save_confirmed():
	var path = $Save.current_path
	emit_signal("tile_set_saved", path.get_basename() + ".tres")


func _on_Load_file_selected(path):
	emit_signal("tile_set_loaded", path)


func _on_New_file_selected(path):
	emit_signal("image_loaded", path)
