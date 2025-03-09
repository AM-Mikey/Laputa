extends Control

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

var texture
var columns: int
var rows: int

var hovered_button
var selected_tile_region := Rect2i(0, 0, 16, 16) #in texture space
#var selected_tiles = [] #2D array
var tile_rotation_degrees: float = 0
var tile_scale_vector := Vector2(1,1)

#tooltip discriptions
var auto_layer_disc = "Auto-Select Drawing Layer"
var multi_erase_disc = "Erase on All Layers"
var auto_tile_disc = "Autotile"
var mode_disc = "Mode"


@export var buttons: NodePath
@export var cursor: NodePath

@onready var editor = get_parent().get_parent().get_parent().get_parent()
@onready var tile_master = editor.get_node("TileMaster")
@onready var auto_layer = $VBox/HBox/AutoLayer
@onready var multi_erase = $VBox/HBox/MultiErase
@onready var auto_tile = $VBox/HBox/AutoTile
@onready var mode = $VBox/HBox/Mode


func setup_tiles():
	tile_master.setup_tile_buttons(self, buttons)

func setup_options(): #AutoLayer, Mode, Etc... TODO: use this if you need to set up defaults
	auto_layer.button_pressed = editor.auto_layer
	multi_erase.button_pressed = editor.multi_erase
	auto_tile.button_pressed = editor.auto_layer
	#mode needs no default, always default to paint
	_on_AutoLayer_toggled(auto_layer.button_pressed)
	_on_MultiErase_toggled(multi_erase.button_pressed)
	_on_AutoTile_toggled(auto_tile.button_pressed)
	mode.tooltip_text = mode_disc + ": Paint"



func transform_buttons():
	var tiles = []
	for c in get_node(buttons).get_children():
		for g in c.get_children():
			tiles.append(g)
	for t in tiles:
		t.rotation = tile_rotation_degrees
		t.scale = tile_scale_vector
	emit_signal("tile_transform_updated")



func hover_button(button):
	hovered_button = button
func unhover():
	hovered_button = null


func _input(event):
	if event.is_action_pressed("editor_lmb") and hovered_button:
		print("started selecting tile: ", hovered_button.tile_set_position)
		selected_tile_region = Rect2i(hovered_button.tile_set_position, Vector2(16, 16))
		editor.brush = null
		print("cleared brush")


	if event.is_action_released("editor_lmb"):
		await get_tree().process_frame
		if hovered_button:
			print("ended selecting tile: ", hovered_button.tile_set_position)
			var start_position = selected_tile_region.position
			var end_position = hovered_button.tile_set_position
			
			var offset = Vector2.ZERO
			if start_position.x <= end_position.x: #left to right
				offset.x += 16
			if start_position.y <= end_position.y: #top to bottom
				offset.y += 16
			
			selected_tile_region = selected_tile_region.expand(end_position + offset)
			set_cursor()
			editor.brush = Rect2i(selected_tile_region.position / 16, selected_tile_region.size / 16) #flatten to integers


#func get_brush() -> Dictionary:
	#var brush = {}
	##creates a 2D array in a dictionary
	##{layer 1:
	##[[(0,0), (0,1), (0,2)], 
	##[(1,0), (1,1), (1,2)]]}
	#if editor.auto_layer:
		## layer
		#for layer in editor.tile_collection.get_children():
			#brush[layer] = []
			##row
			#for row in get_node(buttons).get_children():
				#var row_index = get_node(buttons).get_children().find(row) + 1
				#var layer_index = brush.keys().find(layer) + 1
				#if layer_index * 4 >= row_index and (layer_index - 1) * 4 < row_index:
					#var row_selection = []
					##column
					#for button in row.get_children():
						#if selected_tile_region.encloses(Rect2(button.tile_set_position, Vector2(16, 16))):
							#row_selection.append(button.tile_set_position)
					#if not row_selection.is_empty():
						#brush[layer].append(row_selection)
#
	#else: #no auto_layer
		#brush[editor.tile_map] = []
		##row
		#for row in get_node(buttons).get_children():
			#var row_selection = []
			##column
			#for button in row.get_children():
				#if selected_tile_region.encloses(Rect2(button.tile_set_position, Vector2(16, 16))):
					#row_selection.append(button.tile_set_position)
			#if not row_selection.is_empty():
				#brush[editor.tile_map].append(row_selection)
	#return brush


func set_cursor():
	var x_pos = selected_tile_region.position.x + (floor(selected_tile_region.position.x / 16) * tile_master.tile_separation)
	var y_pos = selected_tile_region.position.y + (floor(selected_tile_region.position.y / 16) * tile_master.tile_separation)
	get_node(cursor).position = Vector2(x_pos, y_pos) 
	var x_size = selected_tile_region.size.x + (floor(selected_tile_region.size.x / 16) * tile_master.tile_separation)
	var y_size = selected_tile_region.size.y + (floor(selected_tile_region.size.y / 16) * tile_master.tile_separation)
	get_node(cursor).size = Vector2(x_size, y_size) 


### SIGNALS ###

func _on_AutoLayer_toggled(button_pressed):
	if button_pressed:
		auto_layer.icon = auto_layer_true
		auto_layer.tooltip_text = auto_layer_disc + ": On"
	else:
		auto_layer.icon = auto_layer_false
		auto_layer.tooltip_text = auto_layer_disc + ": Off"
	editor.auto_layer = button_pressed

func _on_MultiErase_toggled(button_pressed):
	if button_pressed:
		multi_erase.icon = multi_erase_true
		multi_erase.tooltip_text = multi_erase_disc + ": On"
	else:
		multi_erase.icon = multi_erase_false
		multi_erase.tooltip_text = multi_erase_disc + ": Off"
	editor.multi_erase = button_pressed

func _on_AutoTile_toggled(button_pressed):
	if button_pressed:
		auto_tile.icon = auto_tile_true
		auto_tile.tooltip_text = auto_tile_disc + ": On"
	else:
		auto_tile.icon = auto_tile_false
		auto_tile.tooltip_text = auto_tile_disc + ": Off"
	pass # Replace with function body TODO: what??

func _on_Mode_pressed():
	if editor.active_tool == "tile":
		match editor.subtool:
			"paint", "rectangle", "line":
				mode.icon = mode_select
				mode.tooltip_text = mode_disc + ": Select"
				editor.set_tool("tile", "select")
			"select":
				mode.icon = mode_paint
				mode.tooltip_text = mode_disc + ": Paint"
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
