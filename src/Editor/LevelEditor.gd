extends Control

onready var w = get_tree().get_root().get_node("World")

onready var tilemap = w.current_level.get_node("Tiles").get_node("Collision") #get_child(0)
onready var tileset = tilemap.tile_set


export(NodePath) var tile_list


var tiles = {}
var active_tile: int
var lmb_held = false
var rmb_held = false

var mouse_start_pos

var shift_held = false
var ctrl_held = false

var operations = []
var held_trace = []

func _ready():
	var list_id = 0
	
	for i in tileset.get_tiles_ids():
		tiles[list_id] = i
		
		var tile_name = tileset.tile_get_name(i)
		get_node(tile_list).add_item(tile_name, get_tile_texture(i))
		list_id += 1


func get_tile_texture(tile):
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = tileset.tile_get_texture(tile)
	tile_texture.region = tileset.tile_get_region(tile)
	return tile_texture


func _on_TileList_item_selected(index):
	active_tile = tiles[index]

func _unhandled_input(event):
	var mouse_pos = w.get_global_mouse_position()
	
	if event.is_action_pressed("editor_lmb") and active_tile:
		lmb_held = true
		if ctrl_held:
			mouse_start_pos = mouse_pos
		else:
			set_tiles(get_cell(mouse_pos), active_tile)

	if event.is_action_released("editor_lmb"):
		if not held_trace.empty():
			operations.append(["set_tiles", held_trace])
			held_trace.clear
		if ctrl_held:
			draw_box(mouse_start_pos, mouse_pos)
		lmb_held = false


	if event.is_action_pressed("editor_rmb"):
		rmb_held = true
		if ctrl_held:
			mouse_start_pos = mouse_pos
		else:
			set_tiles(get_cell(mouse_pos), -1)

	if event.is_action_released("editor_rmb"):
		if ctrl_held:
			erase_box(mouse_start_pos, mouse_pos)
		rmb_held = false


	if event is InputEventMouseMotion:
		if lmb_held and not ctrl_held:
			set_tiles(get_cell(mouse_pos), active_tile)
		if rmb_held and not ctrl_held:
			set_tiles(get_cell(mouse_pos), -1)
		
		hide_preview()
#		if ctrl_held and lmb_held or ctrl_held and rmb_held:
#			show_box_preview(mouse_start_pos, mouse_pos)
#		elif active_tile:
#			show_tile_preview(get_cell(mouse_pos))


	
	if event.is_action_pressed("editor_ctrl"):
		ctrl_held = true
	if event.is_action_released("editor_ctrl"):
		ctrl_held = false
	if event.is_action_pressed("editor_shift"):
		shift_held = true
	if event.is_action_released("editor_shift"):
		shift_held = false

	if event is InputEventKey and event.is_pressed() and event.scancode == KEY_Z and not event.is_echo():
		if ctrl_held and not shift_held:
			undo()
		if ctrl_held and shift_held:
			redo()


func undo():
	var last = operations.pop_back()
	
	if last:
		match last[0]:
			"set_tiles":
				for t in last[1]: #held trace
					set_tiles([t[0]], t[2], false) #pos_array, old_tile
#
#			"draw_tile":
#				draw_tile(last[1], last[3], false)
	#		"draw_box":
	#			erase_box(last_operation[1], false)
	#		"erase_box":
	#			erase_box(last_operation[1], false)

	
func redo():
	pass


### OPERATIONS ###

#func draw_tile(mouse_pos, tile = active_tile, traced = true):
#	var old_tile = tilemap.get_cellv(get_cell(mouse_pos))
#	tilemap.set_cellv(get_cell(mouse_pos), tile)
#	if traced:
#		operations.append(["draw_tile", mouse_pos, tile, old_tile])


func set_tiles(pos_array: Array, tile, traced = true):
	for pos in pos_array:
		var old_tile = tilemap.get_cellv(pos)
		tilemap.set_cellv(pos, tile)
		if traced:
			held_trace.append([pos, tile, old_tile])
#	if traced and not lmb_held:
#		operations.append(["set_tiles", held_trace])
#		held_trace.clear()
	

func draw_box(start, end, tile = active_tile, traced = true):
	for t in get_box(start, end):
		tilemap.set_cellv(t, active_tile)
	if traced:
		operations.append(["draw_box", start, end, tile])

func erase_box(start, end, tile = active_tile, traced = true):
	for t in get_box(start, end):
		tilemap.set_cellv(t, -1)
	if traced:
		operations.append(["erase_box", start, end, tile])


### PREVIEW ###

func preview_tiles(pos_array: Array):
	for pos in pos_array:
		var sprite = Sprite.new()
		sprite.texture = get_tile_texture(active_tile)
		sprite.modulate = Color(1, 1, 1, 0.5)
		sprite.centered = false
		sprite.position = pos * 16
		tilemap.add_child(sprite)

func hide_preview():
	for c in tilemap.get_children():
		c.queue_free()

#func show_box_preview(start, end):
#	for t in get_box(start, end):
#		show_tile_preview(t)


### GETTERS ###

func get_box(start, end) -> Array:
	var tiles = []
	var start_tile = get_cell(start)
	var end_tile = get_cell(end)
	for i in range(int(min(start_tile.x, end_tile.x)), int(max(start_tile.x, end_tile.x))+1):
		for j in range(int(min(start_tile.y, end_tile.y)), int(max(start_tile.y, end_tile.y))+1):
			tiles.append(Vector2(i,j))
	return tiles

func get_cell(mouse_pos) -> Array:
	var local_pos = tilemap.to_local(mouse_pos)
	var map_pos = tilemap.world_to_map(local_pos)
	return [map_pos]
