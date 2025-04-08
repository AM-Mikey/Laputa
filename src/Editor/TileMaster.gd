extends Node

var texture
var columns: int
var rows: int

@export var tile_separation: int = 1

@onready var w = get_tree().get_root().get_node("World")
@onready var editor = get_parent()
@onready var tiles_tab = editor.get_node("Main/Win/Tab/Tiles")
@onready var tile_set_tab = editor.get_node("Main/Win/Tab/TileSet")



### SETUP ###
func setup_tile_master():
	texture = w.current_level.get_node("TileMap").tile_set.get_source(0).texture
	columns = floor(texture.get_width()/16)
	rows = floor(texture.get_height()/16)
	
	tiles_tab.setup_options()
	#tiles.setup_tiles() already done in editor
	
	tile_set_tab.setup_tile_set()
	#setup_brushes()


func setup_tile_buttons(caller: Node, parent_path: NodePath):
	var parent = caller.get_node(parent_path)
	for c in parent.get_children(): #clear old rows
		c.free()
###
	parent.add_theme_constant_override("separation", tile_separation)
	var r_id = 0
	for r in rows:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", tile_separation)
		#row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(row)
		var c_id = 0
		for c in columns:
			var button = load("res://src/Editor/Button/TileButton.tscn").instantiate()
			button.tile_set_position = Vector2(c_id*16, r_id*16)
			row.add_child(button)
			button.connect("mouse_entered", Callable(caller, "hover_button").bind(button))
			button.connect("mouse_exited", Callable(caller, "unhover"))

			c_id += 1
		r_id += 1
###

	var used_tile_coords = get_all_tile_coords()
	for i in used_tile_coords:
		
		var used_button = parent.get_child(i.y).get_child(i.x)
		#print("button: ", used_button)
		used_button.set("texture", get_tile_as_texture(i))



### GETTERS ###

func get_all_tile_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	var tile_set = w.current_level.get_node("TileMap").tile_set
	#for i in tile_set.get_source(0).get_tiles_count(): #for only used tiles
		#coords.append(tile_set.get_source(0).get_tile_id(i))
	var size = (tile_set.get_source(0).texture.get_size()) / 16.0
	for column in size.x:
		for tile in size.y:
			coords.append(Vector2i(column, tile))
	return coords

func get_tile_as_texture(coords: Vector2i) -> Texture2D:
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = texture
	tile_texture.region = Rect2(coords * 16, Vector2(16,16)) #only works on tiles of size 1
	return tile_texture
