extends Control

signal tile_selection_updated(tile_selection)
signal autolayer_updated(is_autolayer)
signal multi_erase_toggled(toggle)


var tileset 
var texture
var columns
var rows

var hovered_tile
var selected_tile_region = Vector2.ZERO #Top Left ID, Bottom Right ID
var selected_tiles = []

export var tile_separation: int = 1

export(NodePath) var buttons
export(NodePath) var cursor

func setup_tileset(new):
	tileset = new
	texture = tileset.tile_get_texture(tileset.get_tiles_ids().front())
	columns = floor(texture.get_width()/16)
	rows = floor(texture.get_height()/16)
	
	setup_tile_buttons()


func setup_tile_buttons():
	#var buttons = get_node(buttons)
#	buttons.add_constant_override("separation", tile_separation)
	
	for c in get_node(buttons).get_children(): #clear old rows
		c.free()
		
	###########################################################################
	get_node(buttons).add_constant_override("separation", tile_separation)
	var r_id = 0
	for r in rows:
		var row = HBoxContainer.new()
		row.add_constant_override("separation", tile_separation)
		get_node(buttons).add_child(row)
		var c_id = 0
		for c in columns:
			var button = load("res://src/Editor/TileButton.tscn").instance()
			row.add_child(button)
			c_id += 1
		r_id += 1


################################
		
		
#	for r in rows:
#		var row = HBoxContainer.new()
#		row.add_constant_override("separation", tile_separation)
#		get_node(buttons).add_child(row)
#		for c in columns:
#			var column = VBoxContainer.new()
#			column.add_constant_override("separation", tile_separation)
#			row.add_child(column)
		
####################################################

	#var texture_last_tile_id = floor(columns * rows) -1

	for i in tileset.get_tiles_ids(): # for i in range(0, texture_last_tile_id):
		var x_pos: int = floor(tileset.tile_get_region(i).position.x/16)
		var y_pos: int = floor(tileset.tile_get_region(i).position.y/16)
		
		var button = get_node(buttons).get_child(y_pos).get_child(x_pos)
		button.id = i
		button.texture = get_tile_as_texture(i)
		button.connect("mouse_entered", self, "hover_tile", [button])
		button.connect("mouse_exited", self, "unhover")



#########################

# OLD
#	get_node(buttons).add_constant_override("separation", tile_separation)
#
#	var r_id = 0
#	for r in rows:
#		var row = HBoxContainer.new()
#		row.add_constant_override("separation", tile_seperation)
#		get_node(buttons).add_child(row)
#
#		var c_id = 0
#		for x in columns:
#			var tile = load("res://src/Editor/TileButton.tscn").instance()
#			var sp_tex = AtlasTexture.new()
#			sp_tex.atlas = texture
#			sp_tex.region = Rect2(c_id * 16, r_id * 16, 16, 16)
#
#			tile.id = r_id * columns + c_id
#			tile.texture = sp_tex
#			row.add_child(tile)
#			tile.connect("mouse_entered", self, "hover_tile", [tile])
#			tile.connect("mouse_exited", self, "unhover")
#			c_id +=1
#
#		r_id += 1
	
	
	
	
	
#OLD OLD
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

func get_tile_as_texture(id) -> Texture:
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = texture
	tile_texture.region = tileset.tile_get_region(id)
	return tile_texture



func hover_tile(tile):
	hovered_tile = tile.id
func unhover():
	hovered_tile = null



func _input(event):
	if event.is_action_pressed("editor_lmb") and hovered_tile:
		#print("started ", hovered_tile)
		selected_tile_region.x = hovered_tile
	
	if event.is_action_released("editor_lmb") and hovered_tile:
		#print("ended ", hovered_tile)
		selected_tile_region.y = hovered_tile
		set_cursor()
		emit_signal("tile_selection_updated", selected_tile_region)



func set_cursor():
	var start_id = int(min(selected_tile_region.x, selected_tile_region.y))
	var end_id = int(max(selected_tile_region.x, selected_tile_region.y))
	var x0 = (start_id % columns) * 17
	var y0 = floor(start_id / columns) * 17
	var x1 = (end_id % columns+1) * 17
	var y1 = floor(end_id / columns+1) * 17
	var dx = x1 - x0
	var dy = y1 - y0
	get_node(cursor).rect_position = Vector2(x0, y0)
	get_node(cursor).rect_size = Vector2(dx, dy)



func _on_AutoLayer_toggled(button_pressed):
	emit_signal("autolayer_updated", button_pressed)


func _on_MultiErase_toggled(button_pressed):
	emit_signal("multi_erase_toggled", button_pressed)
