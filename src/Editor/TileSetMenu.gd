extends Control

var tileset = load("res://src/Tile/VillageMinimal.tres")
var texture = tileset.tile_get_texture(0)
var columns = int(texture.get_size().x/16)
var rows = int(texture.get_size().y/16)

var hovered_tile
var selected_tile_region = Vector2.ZERO #Vector2: Top Left, Vector2: Bottom Right
var selected_tiles = []


func _ready():
	#$Control.rect_size = texture.get_size()
	import_tileset()
	



	
func import_tileset():
	var r_id = 0
	for y in rows:
		var row = HBoxContainer.new()
		row.add_constant_override("separation", 1)
		$VBox.add_child(row)
		
		var c_id = 0
		for x in columns:
			var tile = load("res://src/Editor/TileButton.tscn").instance()
			var sp_tex = AtlasTexture.new()
			sp_tex.atlas = texture
			sp_tex.region = Rect2(c_id * 16, r_id * 16, 16, 16)
			tile.id = r_id * columns + c_id
			tile.texture = sp_tex
			row.add_child(tile)
			#tile.connect("button_down", self, "start_selection", [tile])
			tile.connect("mouse_entered", self, "hover_tile", [tile])
			tile.connect("mouse_exited", self, "unhover")
			#tile.connect("gui_input", self, "select_tile", [tile])
			c_id +=1
		
		r_id += 1
	
	
	tileset.clear()
	
	var id = tileset.get_last_unused_tile_id()
	while id < rows * columns:
		tileset.create_tile(id)
		tileset.tile_set_texture(id, texture)
		
		var x_pos = (id % columns) * 16
		var y_pos = floor(id / columns) * 16
		var region = Rect2(x_pos, y_pos, 16, 16)
		tileset.tile_set_region(id, region)
		id += 1
		print("added")

func hover_tile(tile):
	hovered_tile = tile.id
	print(tile.id)

func unhover():
	#hovered_tiles.erase(tile.id)
	hovered_tile = null

func start_selection(tile):
	print("started ", tile.id)
	selected_tile_region.x = tile.id


func _input(event):
	if event.is_action_pressed("editor_lmb") and hovered_tile:
		print("started ", hovered_tile)
		selected_tile_region.x = hovered_tile
	if event.is_action_released("editor_lmb") and hovered_tile:
		print("ended ", hovered_tile)
		selected_tile_region.y = hovered_tile
		set_cursor()



func set_cursor():
	var start_id = int(min(selected_tile_region.x, selected_tile_region.y))
	var end_id = int(max(selected_tile_region.x, selected_tile_region.y))
	var x0 = (start_id % columns) * 17
	var y0 = floor(start_id / columns) * 17
	var x1 = (end_id % columns+1) * 17
	var y1 = floor(end_id / columns+1) * 17
	var dx = x1 - x0
	var dy = y1 - y0
	$Control/Cursor.rect_position = Vector2(x0, y0)
	$Control/Cursor.rect_size = Vector2(dx, dy)

