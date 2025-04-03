extends Control

signal terrain_toggled(toggled)
signal tile_transform_updated(tile_rotation_degrees, tile_scale_vector)

var icon = "res://assets/Icon/TileSetIcon.png"

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
var brush_region := Rect2i(0, 0, 16, 16) #in texture space
var tile_rotation_degrees: float = 0
var tile_scale_vector := Vector2(1,1)

#tooltip discriptions
var multi_erase_disc = "Erase on All Layers"
var auto_tile_disc = "Autotile"
var mode_disc = "Mode"


@export var buttons: NodePath
@export var cursor: NodePath

@onready var editor = get_parent().get_parent().get_parent().get_parent()
@onready var tile_master = editor.get_node("TileMaster")
@onready var multi_erase = $VBox/HBox/MultiErase
@onready var auto_tile = $VBox/HBox/AutoTile
@onready var mode = $VBox/HBox/Mode


func setup_tiles():
	editor.connect("tab_changed", Callable(self, "on_tab_changed"))
	tile_master.setup_tile_buttons(self, buttons)

func setup_options(): #AutoLayer, Mode, Etc... TODO: use this if you need to set up defaults
	multi_erase.button_pressed = editor.multi_erase
	auto_tile.button_pressed = editor.auto_tile
	#mode needs no default, always default to paint
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
		brush_region = Rect2i(hovered_button.tile_set_position / 16, Vector2(1, 1))
		editor.brush = null


	if event.is_action_released("editor_lmb"):
		await get_tree().process_frame #why?
		if hovered_button:
			var start_position = brush_region.position
			var end_position = hovered_button.tile_set_position / 16
			
			if start_position.x <= end_position.x: #left to right
				end_position.x += 1
			if start_position.y <= end_position.y: #top to bottom
				end_position.y += 1
			
			brush_region = brush_region.expand(end_position)
			var layer = floor(start_position.y / 4)
			brush_region = clamp_brush_region(layer)
			set_cursor()
			editor.on_layer_changed(layer)
			editor.brush = brush_region


func clamp_brush_region(layer) -> Rect2i:
	var out = brush_region
	
	var clamp_region = Rect2i(0, layer * 4, 9999, 4)
	out = out.intersection(clamp_region)
	return out


func set_cursor():
	var x_pos = brush_region.position.x + (floor(brush_region.position.x * 16) * tile_master.tile_seperation)
	var y_pos = brush_region.position.y + (floor(brush_region.position.y * 16) * tile_master.tile_seperation)
	get_node(cursor).position = Vector2(x_pos, y_pos) 
	var x_size = brush_region.size.x + (floor(brush_region.size.x * 16) * tile_master.tile_seperation)
	var y_size = brush_region.size.y + (floor(brush_region.size.y * 16) * tile_master.tile_seperation)
	get_node(cursor).size = Vector2(x_size, y_size) 


### SIGNALS ###

func on_tab_changed(tab_name):
	pass

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
	editor.auto_tile = button_pressed

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
