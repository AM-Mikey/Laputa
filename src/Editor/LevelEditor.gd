extends Control

const EDITOR_LAYER = preload("res://src/Editor/EditorLayer.tscn")

onready var w = get_tree().get_root().get_node("World")

onready var tilemap = w.current_level.get_node("Tiles").get_node("Collision") #get_child(0)
onready var tileset = tilemap.tile_set


export(NodePath) var tile_list
export(NodePath) var layer_list


var tiles = {}
var active_tile: int

var layers = {}
var active_layer

var brush = "paint"
var mouse_start_pos
var lmb_held = false
var rmb_held = false
var shift_held = false
var ctrl_held = false

var past_operations = [] #[[op][op][op]]
var future_operations = [] #[[op][op][op]]
var active_operation = [] #[[subop][subop][subop]]

func _ready():
	setup_tiles()
	setup_layers()


func setup_tiles():
	var list_id = 0
	
	for i in tileset.get_tiles_ids():
		tiles[list_id] = i
		
		var tile_name = tileset.tile_get_name(i)
		get_node(tile_list).add_item(tile_name, get_tile_texture(i))
		list_id += 1

func setup_layers():
	for l in w.current_level.get_node("Tiles").get_children():
		layers[l.name] = l
		
		var editor_layer = EDITOR_LAYER.instance()
		editor_layer.layer = l
		get_node(layer_list).add_child(editor_layer)
	
	
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
		future_operations.clear()
		mouse_start_pos = mouse_pos
		
		if shift_held:
			brush = "line"
		elif ctrl_held:
			brush = "box"
		else:
			brush = "paint"
			set_tiles([get_cell(mouse_pos)], active_tile)


	if event.is_action_released("editor_lmb"):
		lmb_held = false
		if brush == "line":
			set_tiles(get_line(mouse_start_pos, mouse_pos), active_tile)
		elif brush == "box":
			set_tiles(get_box(mouse_start_pos, mouse_pos), active_tile)
		
		if not active_operation.empty():
			past_operations.append(["set_tiles", active_operation.duplicate()])
			#print("active op: ", active_operation)
			active_operation.clear()



	if event.is_action_pressed("editor_rmb"):
		rmb_held = true
		future_operations.clear()
		mouse_start_pos = mouse_pos
		if shift_held:
			brush = "line"
		elif ctrl_held:
			brush = "box"
		else:
			brush = "paint"
			set_tiles([get_cell(mouse_pos)], -1)


	if event.is_action_released("editor_rmb"):
		rmb_held = false
		if brush == "line":
			set_tiles(get_line(mouse_start_pos, mouse_pos), -1)
		elif brush == "box":
			set_tiles(get_box(mouse_start_pos, mouse_pos), -1)
		
		if not active_operation.empty():
			past_operations.append(["set_tiles", active_operation.duplicate()])
			#print("active op: ", active_operation)
			active_operation.clear()




	if event is InputEventMouseMotion:
		if lmb_held and brush == "paint":
			set_tiles([get_cell(mouse_pos)], active_tile)
		if rmb_held and brush == "paint":
			set_tiles([get_cell(mouse_pos)], -1)
		
		hide_preview()
		if brush == "paint":
			preview_tiles([get_cell(mouse_pos)])
		
		elif lmb_held or rmb_held:
			if brush == "line":
				preview_tiles(get_line(mouse_start_pos, mouse_pos))
			if brush == "box":
				preview_tiles(get_box(mouse_start_pos, mouse_pos))



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
	var last = past_operations.pop_back()
	
	if last:
		future_operations.append(last)
		print("undoing operation: ", last)
		
		match last[0]:
			"set_tiles":
				for t in last[1]: #subops
					set_tiles([t[0]], t[2], false) #pos_array, old_tile, traced
#	else:
#		print("nothing left to undo!")


func redo():
	var next = future_operations.pop_back()
	
	if next:
		past_operations.append(next)
		print("redoing operation: ", next)
		
		match next[0]:
			"set_tiles":
				for t in next[1]: #subops
					set_tiles([t[0]], t[1], false) #pos_array, new_tile, traced
#	else:
#		print("nothing left to redo!")



func set_tiles(pos_array: Array, tile, traced = true):
	for pos in pos_array: #subops
		var old_tile = tilemap.get_cellv(pos)
		tilemap.set_cellv(pos, tile)
		if traced:
			for s in active_operation:
				if s[0] == pos: #positions match
					return
			active_operation.append([pos, tile, old_tile])



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



### GETTERS ###

func get_box(start, end) -> Array:
	var tiles = []
	var start_tile = get_cell(start)
	var end_tile = get_cell(end)
	
	var x_min = min(start_tile.x, end_tile.x)
	var x_max = max(start_tile.x, end_tile.x)
	var y_min = min(start_tile.y, end_tile.y)
	var y_max = max(start_tile.y, end_tile.y)
	
	for i in range(x_min, x_max + 1):
		for j in range(y_min, y_max + 1):
			tiles.append(Vector2(i, j))
	return tiles


func get_cell(mouse_pos) -> Vector2:
	var local_pos = tilemap.to_local(mouse_pos)
	var map_pos = tilemap.world_to_map(local_pos)
	return map_pos


func get_line(start, end) -> Array:
	var tiles = []
	var start_tile = get_cell(start)
	var end_tile = get_cell(end)
	
	var dx = end_tile.x - start_tile.x
	var dy = end_tile.y - start_tile.y
	if dx == 0:
		dx = .0001
	
	if abs(dx) >= abs(dy):
		for x in range(start_tile.x, end_tile.x+1) if start_tile.x < end_tile.x else range(end_tile.x, start_tile.x+1):
			var y = round(start_tile.y + dy * (x - start_tile.x) / dx)
			tiles.append(Vector2(x,y))
	else:
		for y in range(start_tile.y, end_tile.y+1) if start_tile.y < end_tile.y else range(end_tile.y, start_tile.y+1):
			var x = round(start_tile.x + dx * (y - start_tile.y) / dy)
			tiles.append(Vector2(x,y))
	
	return tiles
