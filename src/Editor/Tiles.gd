extends Control

signal tile_selection_updated(selected_tiles)
signal autolayer_updated(is_autolayer)
signal multi_erase_toggled(toggle)


var tileset 
var texture
var columns: int
var rows: int

var hovered_tile
var selected_tile_region: Rect2 = Rect2(0, 0, 16, 16) #in texture space
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
	for c in get_node(buttons).get_children(): #clear old rows
		c.free()
###
	get_node(buttons).add_constant_override("separation", tile_separation)
	var r_id = 0
	for r in rows:
		var row = HBoxContainer.new()
		row.add_constant_override("separation", tile_separation)
		#row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		get_node(buttons).add_child(row)
		var c_id = 0
		for c in columns:
			var button = load("res://src/Editor/TileButton.tscn").instance()
			row.add_child(button)
			button.connect("mouse_entered", self, "hover_tile", [button])
			button.connect("mouse_exited", self, "unhover")
			c_id += 1
		r_id += 1
###
	for i in tileset.get_tiles_ids(): # for i in range(0, texture_last_tile_id):
		var x_pos: int = floor(tileset.tile_get_region(i).position.x/16)
		var y_pos: int = floor(tileset.tile_get_region(i).position.y/16)
		
		var button = get_node(buttons).get_child(y_pos).get_child(x_pos)
		button.id = i
		button.texture = get_tile_as_texture(i)
#		button.connect("mouse_entered", self, "hover_tile", [button])
#		button.connect("mouse_exited", self, "unhover")



func get_tile_as_texture(id) -> Texture:
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = texture
	tile_texture.region = tileset.tile_get_region(id)
	return tile_texture



func hover_tile(tile):
	hovered_tile = tile.id
	#print("hovered: ", hovered_tile)
func unhover():
	hovered_tile = null


func _input(event):
	
	if event.is_action_pressed("editor_lmb") and hovered_tile != null:
		print("started ", hovered_tile)
		selected_tile_region = tileset.tile_get_region(hovered_tile)
		selected_tiles.clear()


	if event.is_action_released("editor_lmb") and hovered_tile != null:
		yield(get_tree(), "idle_frame")
		print("ended ", hovered_tile)
		if hovered_tile != null:
			var start_position = selected_tile_region.position
			var end_position = tileset.tile_get_region(hovered_tile).position
			
			var offset = Vector2.ZERO
			if start_position.x <= end_position.x: #left to right
				offset.x += 16
			if start_position.y <= end_position.y: #top to bottom
				offset.y += 16
			
			selected_tile_region = selected_tile_region.expand(end_position + offset)
			set_selection()





func set_selection():
	set_cursor()
	for i in tileset.get_tiles_ids():
		if selected_tile_region.encloses(tileset.tile_get_region(i)): #not working proepr;y
			selected_tiles.append(i)
	print("region: ", selected_tile_region)
	print("selected: ", selected_tiles)
	emit_signal("tile_selection_updated", selected_tiles)


func set_cursor():
	var x_pos = selected_tile_region.position.x + (floor(selected_tile_region.position.x / 16) * tile_separation)
	var y_pos = selected_tile_region.position.y + (floor(selected_tile_region.position.y / 16) * tile_separation)
	get_node(cursor).rect_position = Vector2(x_pos, y_pos) 
	var x_size = selected_tile_region.size.x + (floor(selected_tile_region.size.x / 16) * tile_separation)
	var y_size = selected_tile_region.size.y + (floor(selected_tile_region.size.y / 16) * tile_separation)
	get_node(cursor).rect_size = Vector2(x_size, y_size) 
	


func _on_AutoLayer_toggled(button_pressed):
	emit_signal("autolayer_updated", button_pressed)


func _on_MultiErase_toggled(button_pressed):
	emit_signal("multi_erase_toggled", button_pressed)
