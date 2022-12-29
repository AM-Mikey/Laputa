extends Control

signal tile_selection_updated(selected_tiles)
signal terrain_toggled(toggled)
signal tile_transform_updated(tile_rotation_degrees, tile_scale_vector)

var icon = "res://assets/Icon/TileSetIcon.png"

var auto_layer_true = load("res://assets/Editor/AutoLayerTrue.png")
var auto_layer_false = load("res://assets/Editor/AutoLayerFalse.png")
var multi_erase_true = load("res://assets/Editor/MultiEraseTrue.png")
var multi_erase_false = load("res://assets/Editor/MultiEraseFalse.png")
var auto_tile_true = load("res://assets/Editor/AutoTileTrue.png")
var auto_tile_false = load("res://assets/Editor/AutoTileFalse.png")
var mode_paint = load("res://assets/Editor/ModePaint.png")
var mode_select = load("res://assets/Editor/ModeSelect.png")

var tile_set 
var texture
var columns: int
var rows: int

var hovered_button
var selected_tile_region := Rect2(0, 0, 16, 16) #in texture space
var selected_tiles = [] #2D array
var tile_rotation_degrees: float = 0
var tile_scale_vector := Vector2(1,1)

export var tile_separation: int = 1

export(NodePath) var buttons
export(NodePath) var cursor

onready var editor = get_parent().get_parent().get_parent()
onready var auto_layer = $VBox/HBox/AutoLayer
onready var multi_erase = $VBox/HBox/MultiErase
onready var auto_tile = $VBox/HBox/AutoTile
onready var mode = $VBox/HBox/Mode



func _ready():
	setup_options()

func setup_options(): #AutoLayer, Mode, Etc... TODO: use this if you need to set up defaults
	auto_layer.pressed = editor.auto_layer
	multi_erase.pressed = editor.multi_erase
	auto_layer.pressed = editor.auto_layer
	#mode needs no default, always default to paint


func setup_tile_set(new):
	tile_set = new
	texture = tile_set.tile_get_texture(tile_set.get_tiles_ids().front())
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
		var button = get_node(buttons).get_child(y_pos).get_child(x_pos)
		button.id = i
		button.texture = get_tile_as_texture(i)
		

func transform_buttons():
	var tiles = []
	for c in get_node(buttons).get_children():
		for g in c.get_children():
			tiles.append(g)
	for t in tiles:
		t.rect_rotation = tile_rotation_degrees
		t.rect_scale = tile_scale_vector
	emit_signal("tile_transform_updated")


func get_tile_as_texture(id) -> Texture:
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = texture
	tile_texture.region = tile_set.tile_get_region(id)
	return tile_texture



func hover_button(button):
	hovered_button = button
func unhover():
	hovered_button = null


func _input(event):
	if event.is_action_pressed("editor_lmb") and hovered_button:
		#print("started ", hovered_button.id)
		selected_tile_region = Rect2(hovered_button.tile_set_position, Vector2(16, 16))
		selected_tiles.clear()


	if event.is_action_released("editor_lmb"):
		yield(get_tree(), "idle_frame")
		if hovered_button:
			#print("ended ", hovered_button.id)
			
			var start_position = selected_tile_region.position
			var end_position = hovered_button.tile_set_position
			
			var offset = Vector2.ZERO
			if start_position.x <= end_position.x: #left to right
				offset.x += 16
			if start_position.y <= end_position.y: #top to bottom
				offset.y += 16
			
			selected_tile_region = selected_tile_region.expand(end_position + offset)
			set_selection()




func set_selection():
	set_cursor()
	#appends to a 2D array
	#[[1, 2, 3], 
	#[4, 5, 6]]
	for r in get_node(buttons).get_children():
		var row_selection = []
		for b in r.get_children():
			if selected_tile_region.encloses(Rect2(b.tile_set_position, Vector2(16, 16))):
				row_selection.append(b.id)
		if not row_selection.empty():
			selected_tiles.append(row_selection)
	
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
	

### SIGNALS ###

func _on_AutoLayer_toggled(button_pressed):
	if button_pressed:
		auto_layer.icon = auto_layer_true
	else:
		auto_layer.icon = auto_layer_false
	editor.auto_layer = button_pressed

func _on_MultiErase_toggled(button_pressed):
	if button_pressed:
		multi_erase.icon = multi_erase_true
	else:
		multi_erase.icon = multi_erase_false
	editor.multi_erase = button_pressed

func _on_AutoTile_toggled(button_pressed):
	if button_pressed:
		auto_tile.icon = auto_tile_true
	else:
		auto_tile.icon = auto_tile_false
	pass # Replace with function body.

func _on_Mode_pressed():
	if editor.active_tool == "tile":
		match editor.subtool:
			"paint", "rectangle", "line":
				mode.icon = mode_select
				editor.set_tool("tile", "select")
			"select":
				mode.icon = mode_paint
				editor.set_tool("tile", "paint")



func _on_FlipH_toggled(button_pressed):
	tile_scale_vector.x = -1 if button_pressed else 1
	transform_buttons()

func _on_FlipV_toggled(button_pressed):
	tile_scale_vector.y = -1 if button_pressed else 1
	transform_buttons()
	#emit_signal("tile_transform_updated", tile_rotation_degrees, tile_scale_vector)

func _on_RotateC_pressed():
	if tile_rotation_degrees == 270:
		tile_rotation_degrees = 0
	else:
		tile_rotation_degrees += 90
	transform_buttons()
	#emit_signal("tile_transform_updated", tile_rotation_degrees, tile_scale_vector)

func _on_RotateCC_pressed():
	if tile_rotation_degrees == 0:
		tile_rotation_degrees = 270
	else:
		tile_rotation_degrees -= 90
	transform_buttons()
	#emit_signal("tile_transform_updated", tile_rotation_degrees, tile_scale_vector)
