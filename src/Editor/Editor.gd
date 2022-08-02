extends Control

#signal enemy_selected(enemy)
#signal prop_selected(prop)
signal entity_selected(entity, entity_type)
signal level_selected(level)
signal tile_collection_selected(tile_collection)

signal level_saved()


const EDITOR_CAMERA = preload("res://src/Editor/EditorCamera.tscn")
const ENTITY_PREVIEW = preload("res://src/Editor/EntityPreview.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const LAYER_BUTTON = preload("res://src/Editor/Button/LayerButton.tscn")
const LIMITER = preload("res://src/Editor/EditorLevelLimiter.tscn")
const TRIGGER_CONTROLLER = preload("res://src/Editor/TriggerController.tscn")


var disabled = false

var active_tiles = [] #2D array

var auto_layer = true
var multi_erase = true

var active_tool = "tile"
var subtool = "paint"
var mouse_start_pos
var grab_offset = Vector2()
var pre_grab_subtool: String
var lmb_held = false
var rmb_held = false
var shift_held = false
var ctrl_held = false

var past_operations = [] #[[op][op][op]]
var future_operations = [] #[[op][op][op]]
var active_operation = [] #[[subop][subop][subop]]


onready var w = get_tree().get_root().get_node("World")
onready var ui = w.get_node("UILayer")
onready var el = w.get_node("EditorLayer")
onready var inspector = $Secondary/Inspector
var tile_collection
var actor_collection
var prop_collection
var trigger_collection
var tile_map
var tile_set
var editor_level_limiter


func _ready():
	var _err = get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	connect("tile_collection_selected", inspector, "on_selected", ["tile_collection"])
	connect("level_selected", inspector, "on_selected", ["level"])
	el.add_child(EDITOR_CAMERA.instance())

	
	setup_level() #Call this every time the level is changed or reloaded
	#$Main.move_child($Main/Tab, 0) TODO: was supposed to make tabcontainer go behind resize controls, didnt work

func setup_level():
	#emit_signal("level_selected", w.current_level)
	#get_tree().paused = true
	w.get_node("Juniper").disable()
	ui.get_node("HUD").queue_free()
	for a in get_tree().get_nodes_in_group("Actors"):
		if a.has_method("disable"): #TODO TODO:, better way of doing this and resetting vars at the same time
			a.disable()
	tile_collection = w.current_level.get_node("Tiles")
	actor_collection = w.current_level.get_node("Actors")
	prop_collection = w.current_level.get_node("Props")
	trigger_collection = w.current_level.get_node("Triggers")
	
	tile_map = tile_collection.get_child(0)
	tile_set = w.current_level.tile_set
	on_TileSet_tile_set_loaded(tile_set.resource_path) #so we can set every tile map to the tile set
	setup_level_limiter()
	set_entities_pickable()
	w.set_debug_visible(true)
	move_actors_to_home()
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		s.visible = true
	for l in get_tree().get_nodes_in_group("SunLights"):
		l.editor_enter()

### SETUP
func move_actors_to_home():
	for a in actor_collection.get_children():
		a.global_position = a.home


func set_entities_pickable(pickable = true):
	for a in actor_collection.get_children():
		if not a.is_in_group("Previews"):
			a.input_pickable = pickable
	for p in prop_collection.get_children():
		if not p.is_in_group("Previews"):
			p.input_pickable = pickable
#	for t in trigger_collection.get_children(): #TODO: turned this off as we move to trigger controller system. please turn this on for normal triggers
#		if not t.is_in_group("Previews"):
#			t.input_pickable = pickable

func setup_level_limiter():
	editor_level_limiter = LIMITER.instance()
	var level_layer = Node2D.new()
	level_layer.name = "LevelEditorLayer"
	level_layer.z_index = 8
	w.current_level.add_child(level_layer)
	level_layer.add_child(editor_level_limiter)

func exit():
	#get_tree().paused = false
	inspector.exit()
	
	hide_preview() #delete tile brush preview
	editor_level_limiter.queue_free()
	el.get_node("EditorCamera").queue_free()
	ui.add_child(HUD.instance())
	w.get_node("Juniper").enable()
	w.get_node("Juniper/PlayerCamera").current = true
	for a in get_tree().get_nodes_in_group("Actors"):
		if a.has_method("enable"):
			a.enable()
	set_entities_pickable(false)
	w.set_debug_visible(false)
	move_actors_to_home()
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		s.visible = false
	for l in get_tree().get_nodes_in_group("SunLights"):
		l.editor_exit()
	queue_free()

### TILES

func create_tile_set_from_texture(texture):
	tile_set = TileSet.new()
	var rows = int(texture.get_size().y/16)
	var columns = int(texture.get_size().x/16)

	var id = 0
	while id < rows * columns:
		var x_pos = (id % columns) * 16
		var y_pos = floor(id / columns) * 16
		var region = Rect2(x_pos, y_pos, 16, 16)

		#if texture_alpha_check(texture, region):
		tile_set.create_tile(id)
		tile_set.tile_set_texture(id, texture)
		tile_set.tile_set_region(id, region)
		id += 1

	$Main/Tab/TileSet.setup_tile_set(tile_set)

	for c in tile_collection.get_children():
		if c is TileMap:
			c.tile_set = tile_set


#func texture_alpha_check(texture, region) -> bool: #TODO does not work
#	var image = Image.new()
#	image.load(texture.resource_path)
#	if image.get_rect(region).is_invisible():
#		return true
#	else:
#		return false
##	var pixel_check_count = 0
##	var pixel_pos = Vector2.ZERO
#
##	for row in cropped.get_height():
##		for column in cropped.get_width():
##			var pixel = AtlasTexture.new()
##			pixel.atlas = texture
##			pixel.region = Rect2(column, row, 1, 1)
##			if pixel.has_alpha():
##				pixel_check_count += 1
##
##
##	#if pixel_check_count != 0:
##	print("pixel_check_count:", pixel_check_count)
##	if pixel_check_count == cropped.get_height() * cropped.get_width():
##		return true
##	else:
##		return false





func get_tile_texture(tile):
	var tile_texture = AtlasTexture.new()
	tile_texture.atlas = tile_set.tile_get_texture(tile)
	tile_texture.region = tile_set.tile_get_region(tile)
	return tile_texture


### INPUT ###

func _unhandled_input(event):
	if disabled:
		return
	
	if event.is_action_pressed("editor_ctrl"): ctrl_held = true
	if event.is_action_released("editor_ctrl"): ctrl_held = false
	if event.is_action_pressed("editor_shift"): shift_held = true
	if event.is_action_released("editor_shift"): shift_held = false

	if event is InputEventKey and event.is_pressed() and not event.is_echo() and ctrl_held:
		if event.scancode == KEY_Z:
			if shift_held: redo()
			else: undo()
		if event.scancode == KEY_S:
			emit_signal("level_saved")
	
	
	if event.is_action_pressed("editor_lmb"):
		lmb_held = true
		rmb_held = false #this might fuck things up for other tools
		future_operations.clear()

	if event.is_action_pressed("editor_rmb"):
		rmb_held = true
		#lmb_held = false #this might fuck things up for other tools
		future_operations.clear()

	#main part
	match active_tool:
		"tile": do_tile_input(event)
		"entity": do_entity_input(event)

	#after, just so we can check held during main part
	if event.is_action_released("editor_lmb"):
		lmb_held = false
	if event.is_action_released("editor_rmb"):
		rmb_held = false



func do_entity_input(event):
	yield(get_tree(), "idle_frame") #wait for new active to be set
	
	var mouse_pos = w.get_global_mouse_position() #Vector2(w.get_global_mouse_position().x, w.get_global_mouse_position().y + 8)
	var grid_pos
	if shift_held: grid_pos = get_grid_pos(mouse_pos, "fine")
	else: grid_pos = get_grid_pos(mouse_pos, "course")
	
	var pos_has_enemy = false
	for e in get_tree().get_nodes_in_group("Enemies"):
		if is_entity_at_position(e, grid_pos):
			pos_has_enemy = true
	var pos_has_prop = false
	for p in get_tree().get_nodes_in_group("Props"):
		if is_entity_at_position(p, grid_pos):
			pos_has_enemy = true
	
	

	#placing
	if event.is_action_pressed("editor_lmb"):
		match subtool:
			"enemy":
				if not pos_has_enemy:
					set_entity(grid_pos, $Main/Tab/Enemies.active_enemy_path, subtool) #subtool == "enemy"
			"prop":
				set_entity(grid_pos, $Main/Tab/Props.active_prop_path, subtool)
			"npc":
				set_entity(grid_pos, $Main/Tab/NPCs.active_npc_path, subtool)
			"trigger":
				set_entity(get_grid_pos(mouse_pos, "course", "trigger"), $Main/Tab/Triggers.active_trigger_path, subtool)
			"noplace":
				pass


	#grabbing
	if event.is_action_pressed("editor_rmb") and inspector.active and inspector.active_type != "background":
		pre_grab_subtool = subtool
		set_tool("entity", "grab")
		grab_offset = inspector.active.global_position - grid_pos

	#releasing
	if event.is_action_released("editor_rmb"):
		set_tool("entity", pre_grab_subtool)

	#moving
	if event is InputEventMouseMotion:
		hide_preview()
		match subtool:
			"enemy":
				if not pos_has_enemy:
					preview_entity(grid_pos, $Main/Tab/Enemies.active_enemy_path, subtool)
			"prop":
				preview_entity(grid_pos, $Main/Tab/Props.active_prop_path, subtool)
			"npc":
				preview_entity(grid_pos, $Main/Tab/NPCs.active_npc_path, subtool)
			"trigger":
				preview_entity(get_grid_pos(mouse_pos, "course", "trigger"), $Main/Tab/Triggers.active_trigger_path, subtool)
			"grab":
				inspector.active.global_position = grid_pos + grab_offset
				if "home" in inspector.active:
					inspector.active.home = inspector.active.global_position
	
	#deleting
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.scancode == KEY_DELETE: #or event.scancode == KEY_BACKSPACE or (event.scancode == KEY_X and not ctrl_held)
			if inspector.active:
				if not(inspector.active_type == "background" or inspector.active_type == "spawn_point"):
					inspector.active.queue_free()
					inspector.on_deselected()





func do_tile_input(event):
	var mouse_pos = w.get_global_mouse_position()
	var brush
	
	if lmb_held: brush = active_tiles
	if rmb_held: brush = get_brush_as_eraser()
	
	#pressing
	if event.is_action_pressed("editor_rmb") or event.is_action_pressed("editor_lmb") and not active_tiles.empty():
		mouse_start_pos = mouse_pos
		if shift_held: set_tool("tile", "line")
		elif ctrl_held: set_tool("tile", "box")
		else: 
			set_tool("tile", "paint")
			set_cells_2d(get_centerbox(mouse_pos), brush) #TODO: on all layers
	
	#moving
	if event is InputEventMouseMotion:
		hide_preview()
		match subtool:
			"line": preview_line(get_brush_origin_line(mouse_start_pos, mouse_pos))
			"box": preview_2d_array(get_box_2d(mouse_start_pos, mouse_pos))
			"paint":
				if lmb_held or rmb_held:
					set_cells_2d(get_centerbox(mouse_pos), brush) #TODO: on all layers
				else:
					preview_2d_array(get_centerbox(mouse_pos))
	
	#releasing
	if event.is_action_released("editor_lmb") and lmb_held or event.is_action_released("editor_rmb") and rmb_held:
		match subtool:
			"line": set_line(get_brush_origin_line(mouse_start_pos, mouse_pos), brush) #TODO: on all layers
			"box":
				if lmb_held:
					set_cells_2d(get_box_2d(mouse_start_pos, mouse_pos), brush)
				elif rmb_held:
					set_cells_1d(get_box_1d(mouse_start_pos, mouse_pos), -1)
				
		subtool = "paint"
		if not active_operation.empty():
			past_operations.append(["set_cells", active_operation.duplicate()])
			#print("active op: ", active_operation)
			active_operation.clear()



func do_grab_input(event):
	var mouse_pos = Vector2(w.get_global_mouse_position().x, w.get_global_mouse_position().y - 8) #w.get_global_mouse_position() #
	var grid_pos = get_grid_pos(mouse_pos, "fine")

	#pressing
#	if event.is_action_pressed("editor_rmb"):
#		var selected = get_entity_at_pos(Vector2(grid_pos.x, grid_pos.y + 1))
#		if selected:
#			inspector.on_selected(selected, get_entity_type(selected))
#		else:
#			inspector.on_deselected()
	
	if event.is_action_pressed("editor_rmb") and inspector.active:
		set_tool("grab", "hold")
		grab_offset = inspector.active.position - grid_pos
	
#	if event.is_action_pressed("editor_rmb"):
#		inspector.on_deselected()
	
	#releasing
	if event.is_action_released("editor_rmb"):
		set_tool("grab", "release")

	#moving
	if event is InputEventMouseMotion and subtool == "hold":
		inspector.active.position = grid_pos + grab_offset

#func get_entity_at_pos(position):
#	for a in actor_collection.get_children():
#		if a.position == position:
#			return a
#	for p in prop_collection.get_children():
#		if p.position == position:
#			return p
#	return null

func get_entity_type(entity: Node): #called by actor.gd
	if entity.is_in_group("Enemies"): return "enemy"
	if entity.is_in_group("Props"): return "prop"
	if entity.is_in_group("NPCs"): return "npc"
	if entity.is_in_group("Triggers"): return "trigger"
	if entity.is_in_group("SpawnPoints"): return "spawn_point"
	
	printerr("ERROR: Could not get entity type of entity: " + entity.name)
	return null
	
### OPERATIONS ###




func undo():
	var last = past_operations.pop_back()
	
	if last:
		future_operations.append(last)
		print("undoing operation: ", last)
		
		match inspector.active_type: #get rid of selection to prevent time travel paradoxes
			"enemy", "npc", "prop":
				inspector.on_deselected()
		
		
		match last[0]:
			"set_cells":
				var subops = last[1]
				subops.invert()
				for t in subops:
					var old_tile_dic = t[2]
					for layer in old_tile_dic: #old_tile_dic= {layer: [[cell, tile][cell, tile][cell, tile]]}
						for cell in old_tile_dic[layer]:
							var cell_pos = cell[0]
							var tile = cell[1]
							set_cell(cell_pos, tile, layer)
			"set_entity":
				var arg = last[1]
				del_entity(arg[0], false) #position, traced
	else:
		print("nothing left to undo!")

func redo():
	var next = future_operations.pop_back()
	
	if next:
		past_operations.append(next)
		print("redoing operation: ", next)
		
		match next[0]:
			"set_tiles_1d":
				var subops = next[1]
				subops.invert()
				for t in subops:
					var cell_pos = t[0]
					var tile = t[1]
					set_cells_1d(cell_pos, tile)
					#set_cells_1d([t[0]], t[1], t[3], false) #pos_array, new_tile, layer, traced
			"set_entity":
				var arg = next[1]
				set_entity(arg[0], arg[1], arg[2], false) #position, entity_path, entity_type
	else:
		print("nothing left to redo!")


func set_cell(cell: Vector2, tile: int, layer): #set one cell, one layer, one tile ##ONLY VIA UNDO/REDO
	if tile == -2: #null
		return
	layer.set_cellv(cell, tile)



func set_cells_1d(cells: Array, tile, traced = true): #sets a 1d array of cells with a single tile
	if tile == -2: #null
		return
		
	var old_tile_dic = {} # layer: [[cell, tile][cell, tile][cell, tile]]
	for layer in tile_collection.get_children():
		if layer is TileMap:
			old_tile_dic[layer] = []
		
	for cell in cells: #subops

		var layer = tile_map
		if auto_layer and not tile == -1: #not eraser and auto layer
			layer = get_auto_layer(tile)
		if multi_erase and tile == -1: #eraser
			for l in tile_collection.get_children():
				if l is TileMap:
					
					if l.get_cellv(cell) == tile: #if old tile == new tile
						pass
					else:
						old_tile_dic[l].append([cell, l.get_cellv(cell)])
						l.set_cellv(cell, tile)
		else: #not multi_eraser
			if layer.get_cellv(cell) == tile: #if old tile == new tile
				pass
			else:
				old_tile_dic[layer].append([cell, layer.get_cellv(cell)])
				layer.set_cellv(cell, tile)

	if traced:
#		for s in active_operation:
#			if s[0] == cell: #already setting this cell in the current operation, this prevents reactivating on mouse movement
#				return
		active_operation.append([cells, tile, old_tile_dic])
		print(active_operation)


func set_cells_2d(cells: Array, brush: Array, traced = true):
	if brush.empty():
		return
	var r_id = 0
	var r_max = brush.size()
	for row in cells:
		var c_id = 0
		var c_max = brush[c_id].size()
		for cell in row: #subops
			var tile = brush[r_id % r_max][c_id % c_max] # % so it repeats if cells > tiles
			if tile == -2: pass #null
				
			var old_tile_dic = {}
			
			var layer = tile_map
			var is_eraser = brush == get_brush_as_eraser() #this works as long as nobody added an arguement to get_brush_as_eraser
			
			if multi_erase and is_eraser: 
				for l in tile_collection.get_children():
					if l is TileMap:
						old_tile_dic[l] = l.get_cellv(cell)
						l.set_cellv(cell, tile)
						
			else: #not eraser
				if auto_layer and not is_eraser: #if auto layer is on, still use the current layer as the eraser
					layer = get_auto_layer(tile)
				old_tile_dic[layer] = layer.get_cellv(cell)
				layer.set_cellv(cell, tile)
				
			
			if traced:
#				for s in active_operation:
#					if s[0] == cell and s[1] == tile: #already setting this cell in the current operation, this prevents reactivating on mouse movement
#						return
				active_operation.append([cell, tile, old_tile_dic])


			c_id += 1
		r_id += 1


func set_line(canvas: Array, brush: Array, traced = true):
	if brush.empty():
		return
	var r_id = 0
	var r_max = brush.size()
	for row in canvas:
		var c_id = 0
		var c_max = brush[c_id].size()
		for cell in row: #subops
			var brush_r_id = 0
			for brush_row in brush: #in Active Tiles
				var brush_c_id = 0
				for brush_cell in brush_row:
					var tile = brush_cell
					if tile != -2: #null
						var offset = Vector2(brush_c_id, brush_r_id)
						
						var old_tile_dic = {}
						var layer = tile_map
						if auto_layer:
							layer = get_auto_layer(tile)
						if multi_erase and brush == get_brush_as_eraser(): #this works as long as nobody added an arguement to get_brush_as_eraser
							for l in tile_collection.get_children():
								if l is TileMap:
									l.set_cellv(cell + offset, tile)
									old_tile_dic[l] = l.get_cellv(cell)
						else: #not eraser
							layer.set_cellv(cell + offset, tile)
							old_tile_dic[layer] = layer.get_cellv(cell)
						
						if traced:
							if multi_erase and brush == get_brush_as_eraser():
								active_operation.append([cell + offset, tile, old_tile_dic])
							else:
								active_operation.append([cell + offset, tile, old_tile_dic])
					
					brush_c_id += 1
				brush_r_id +=1
			c_id += 1
		r_id += 1



func set_entity(position, entity_path, entity_type, traced = true):
	if entity_path == null:
		printerr("ERROR: no enemy path in set_entity")
	
	var entity = load(entity_path).instance()
	if entity.has_method("disable"):
		entity.disable()
	entity.global_position = position
	entity.input_pickable = true
	
	match entity_type:
		"enemy", "npc", "player", "boss", "pickup":
			actor_collection.add_child(entity)
		"prop":
			prop_collection.add_child(entity)
		"trigger":
			#entity = TRIGGER_CONTROLLER.instance()
			trigger_collection.add_child(entity)
		_:
			printerr("ERROR: cannot find entity_type: " + entity_type)
	
	entity.owner = w.current_level
	if traced:
		emit_signal("entity_selected", entity, entity_type) #select new entity
		past_operations.append(["set_entity",[position, entity_path, entity_type]])

func del_entity(position, traced = true):
		for e in get_tree().get_nodes_in_group("Entities"):
			if is_entity_at_position(e, position):
				e.queue_free()





### PREVIEW ###

func preview_2d_array(cells: Array):
	var r_id = 0
	var r_max = active_tiles.size()
	for row in cells:
		var c_id = 0
		var c_max = active_tiles[c_id].size()
		for cell in row:
			var tile = active_tiles[r_id % r_max][c_id % c_max] # % so it repeats if cells > tiles
			set_preview(cell, tile)
			c_id += 1
		r_id += 1

func preview_line(cells: Array): #use get_brush_origin for this
	var r_id = 0
	var r_max = active_tiles.size()
	for row in cells:
		var c_id = 0
		var c_max = active_tiles[c_id].size()
		for cell in row:
			
			var br_id = 0
			for b_row in active_tiles:
				var bc_id = 0
				for b_cell in b_row:
					var tile = b_cell
					var offset = Vector2(bc_id, br_id)
					set_preview(cell + offset, tile)
					bc_id += 1
				br_id +=1
			c_id += 1
		r_id += 1

func set_preview(cell, tile):
	if tile == -2: #null
		return
		
	var sprite = Sprite.new()
	sprite.texture = get_tile_texture(tile)
	sprite.modulate = Color(1, 1, 1, 0.5)
	sprite.centered = false
	sprite.position = cell * 16
	sprite.z_index = 2
	tile_collection.add_child(sprite)


func preview_entity(position, entity_path, entity_type):
	var preview = ENTITY_PREVIEW.instance()
	preview.entity_type = entity_type
	preview.entity_path = entity_path
	preview.global_position = position
	match entity_type:
		"enemy", "npc", "player", "boss", "pickup":
			actor_collection.add_child(preview)
		"prop":
			prop_collection.add_child(preview)
		"trigger":
			trigger_collection.add_child(preview)
		_:
			printerr("ERROR: cannot find entity_type: " + entity_type)


func hide_preview():
	for c in tile_collection.get_children():
		if c is Sprite:
			c.queue_free()
	for e in get_tree().get_nodes_in_group("Previews"):
		e.queue_free()



### GETTERS ###

#func get_terrain_tile(position):
#	var cell = get_cell(position) #vector2
#
#	var adjacent = {
#	"n": Vector2(cell.x, cell.y-1),
#	"ne": Vector2(cell.x+1, cell.y-1),
#	"e": Vector2(cell.x+1, cell.y),
#	"se": Vector2(cell.x-1, cell.y+1),
#	"s": Vector2(cell.x, cell.y+1),
#	"sw": Vector2(cell.x-1, cell.y+1),
#	"w": Vector2(cell.x-1, cell.y),
#	"nw": Vector2(cell.x-1, cell.y-1),
#	}
#
#	for c in adjacent:
#		if tile_map.get_cell_v(c) = tile:
#			pass



func get_cell(mouse_pos) -> Vector2:
	var local_pos = tile_map.to_local(mouse_pos)
	var map_pos = tile_map.world_to_map(local_pos)
	return map_pos

func get_grid_pos(mouse_pos, mode = "course", exception = "none") -> Vector2:
	var step = 16
	var offset = Vector2(8,0)
	if mode == "fine":
		step = 8
		offset = Vector2(0, 0)
	if exception == "trigger":
		return Vector2(stepify(mouse_pos.x, step), stepify(mouse_pos.y, step))
	else:
		return Vector2(stepify(mouse_pos.x - offset.x, step), stepify(mouse_pos.y - offset.y, step)) + offset
	

func get_centerbox(mouse_pos) -> Array: #2D Array #active tiles
	var cells = []
	var bx = get_brush_size("x")
	var by = get_brush_size("y")
	
	var center = Vector2(floor(bx/2), floor(by/2))
	var center_cell = get_cell(mouse_pos)
	#assumes an odd number
	for row in by:
		var row_cells = []
		for cell in bx:
			var offset = Vector2(cell - center.x, row - center.y)
			row_cells.append(center_cell + offset) #position of cell in map space
		if not row_cells.empty():
			cells.append(row_cells)
	#print(cells)
	return cells


func get_box_1d(start_pos, end_pos) -> Array: #1d
	var cells = []
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var x_min = min(start.x, end.x)
	var x_max = max(start.x, end.x)
	var y_min = min(start.y, end.y)
	var y_max = max(start.y, end.y)
	
	for y in range(y_min, y_max + 1):
		for x in range(x_min, x_max + 1):
			cells.append(Vector2(x, y))
	#print(cells)
	return cells


func get_box_2d(start_pos, end_pos) -> Array: #2d #TODO: massive slowdown when drawing bigger boxes. memory leak.
	var cells = []
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var x_min = min(start.x, end.x)
	var x_max = max(start.x, end.x)
	var y_min = min(start.y, end.y)
	var y_max = max(start.y, end.y)
	
	for y in range(y_min, y_max + 1):
		var row = []
		for x in range(x_min, x_max + 1):
			row.append(Vector2(x, y))
		cells.append(row)
	#print(cells)
	return cells


#func get_brush_line(start_pos, end_pos) -> Array: #2d #Depreciated, only used for brushes of size = 1, like erasers
#	var cells = []
#	var start = get_cell(start_pos)
#	var end = get_cell(end_pos)
#	var x_min = min(start.x, end.x)
#	var x_max = max(start.x, end.x)
#	var y_min = min(start.y, end.y)
#	var y_max = max(start.y, end.y)
#	var dx = end.x - start.x
#	var dy = end.y - start.y
#	if dx == 0:
#		dx = .0001
#	var bx = get_brush_size("x")
#	var by = get_brush_size("y")
#
#	if abs(dx) >= (float(bx)/float(by)) * abs(dy): #TODO: this division seems to slow down the game with very tall brushes
#		for x in range(x_min, x_max+1):
#			if x % bx == 0: #start of a brush 
#				var y = round(start.y + dy * (x - start.x) / dx)
#
#				for row in by:
#					for cell in bx:
#						cells.append(Vector2(x + cell, y + row))
#
#	else:
#		for y in range(y_min, y_max+1):
#			if y % by == 0: #start of a brush 
#				var x = round(start.x + dx * (y - start.y) / dy)
#
#				for row in by:
#					for cell in bx:
#						cells.append(Vector2(x + cell, y + row))
#
#	#print("cells: ",get_2d_array_from_Vector2_array(cells))
#	return get_2d_array_from_Vector2_array(cells)

func get_brush_origin_line(start_pos, end_pos) -> Array: #2d, only origin points of brushes
	var cells = []
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var x_min = min(start.x, end.x)
	var x_max = max(start.x, end.x)
	var y_min = min(start.y, end.y)
	var y_max = max(start.y, end.y)
	var dx = end.x - start.x
	var dy = end.y - start.y
	if dx == 0:
		dx = .0001
	var bx = get_brush_size("x")
	var by = get_brush_size("y")
	
	if abs(dx) >= (float(bx)/float(by)) * abs(dy): #TODO: this division seems to slow down the game with very tall brushes
		for x in range(x_min, x_max+1):
			if x % bx == 0: #start of a brush 
				var y = round(start.y + dy * (x - start.x) / dx)
				cells.append(Vector2(x, y))
	
	else:
		for y in range(y_min, y_max+1):
			if y % by == 0: #start of a brush 
				var x = round(start.x + dx * (y - start.y) / dy)
				cells.append(Vector2(x, y))
	
	#print("cells: ",get_2d_array_from_Vector2_array(cells))
	return get_2d_array_from_Vector2_array(cells)



### HELPER GETTERS ###

func get_brush_size(axis = "both"):
	var brush_size = Vector2.ZERO
	brush_size.y = active_tiles.size()
	for row in active_tiles:
		if row.size() > brush_size.x:
			brush_size.x = row.size()
	if axis == "x":
		return int(brush_size.x)
	if axis == "y":
		return int(brush_size.y)
	else:
		return brush_size

func get_brush_as_eraser(var null_erase = true) -> Array: #erase with null tiles by default
	var eraser = []
	for row in active_tiles:
		var eraser_row = []
		for tile in row:
			if null_erase: eraser_row.append(-1)
			else: eraser_row.append(-2) if tile == -2 else eraser_row.append(-1) #null if null, else eraser
		eraser.append(eraser_row)
	#print(eraser)
	return eraser

func get_2d_array_from_Vector2_array(array) -> Array:
	var new_array = []
	var recorded_ys = []
	for i in array:
		if not recorded_ys.has(i.y):
			recorded_ys.append(i.y)
			var row = []
			row.append(i)
			new_array.append(row)
		else:
			new_array[recorded_ys.find(i.y)].append(i)
	return new_array


func is_entity_at_position(entity, position, forgiveness = 4):
	var out = false
	if abs(position.x - entity.global_position.x) < forgiveness and abs(position.y - entity.global_position.y) < forgiveness:
		if not entity.is_in_group("Previews"):
			out = true
	return out


### HELPERS

func set_tool(new_tool = "", new_subtool = ""):
	hide_preview()
	active_tool = new_tool
	if new_subtool == "":
		match active_tool: #default subtools
			"tile": new_subtool = "paint"
			"grab": new_subtool = "hold"
			"enemy": new_subtool = "place"
			_: new_subtool = ""
	
	subtool = new_subtool

func get_auto_layer(tile):
	if tile == -1:
		return
	var layer = tile_map
	var tile_pos = tile_set.tile_get_region(tile).position

	match int(floor(tile_pos.y /16 / 4)):
		0: layer = tile_collection.get_child(0)
		1: layer = tile_collection.get_child(1)
		2: layer = tile_collection.get_child(2)
		3: layer = tile_collection.get_child(3)
		_: printerr("ERROR: Could not get auto layer with tile_pos: " + str(tile_pos))
	return layer

func on_layer_changed(layer):
	tile_map = layer

### SIGNALS ###



### TILES SIGNALS

func on_Tiles_tile_selection_updated(selected_tiles):
	active_tiles = selected_tiles

func on_Tiles_autolayer_toggled(toggled):
	auto_layer = toggled

func on_Tiles_multi_erase_toggled(toggled):
	multi_erase = toggled

func on_terrain_toggled(toggle): #DEBUG
	create_tile_set_from_texture(load("res://assets/Tile/VillageTerrain.png"))

func _on_Tiles_tile_transform_updated(tile_rotation_degrees, tile_scale_vector):
	pass # Replace with function body.


### TILESET SIGNALS

func _on_TileSet_collision_updated(tile_id, shape):
	var transform = Transform2D.IDENTITY
	tile_set.tile_add_shape(tile_id, shape, transform)
	tile_set.tile_set_shape(tile_id, 0, shape)

func on_TileSet_image_loaded(path):
	create_tile_set_from_texture(load(path))

func on_TileSet_tile_set_saved(path):
	var err = ResourceSaver.save(path, tile_set)
	if err == OK:
		print("tile set saved")
	else:
		printerr("ERROR: tile set not saved!")

func on_TileSet_tile_set_loaded(path):
	tile_set = load(path)
	$Main/Tab/Tiles.setup_tile_set(tile_set)
	$Main/Tab/TileSet.setup_tile_set(tile_set)
	for c in tile_collection.get_children():
		if c is TileMap:
			c.tile_set = tile_set

### MISC SIGNALS

func _on_viewport_size_changed():
	$Margin.rect_size = get_tree().get_root().size / w.get_node("EditorLayer").scale
	rect_size = get_tree().get_root().size / w.get_node("EditorLayer").scale
	pass

func on_tab_selected(tab_index): #tab buttons
	$Main/Tab.current_tab = tab_index

func on_tab_changed(tab):
	match $Main/Tab.get_child(tab).name:
		"Tiles": 
			set_tool("tile")
			set_entities_pickable(false)
			inspector.on_deselected()
			emit_signal("tile_collection_selected", w.current_level.get_node("Tiles"))
		"TileSet":
			set_tool("tile_set")
		"Levels":
			set_tool("level")
			emit_signal("level_selected", w.current_level)
		
		"Enemies": 
			set_tool("entity", "enemy")
			set_entities_pickable()
		"Props":
			set_tool("entity", "prop")
			set_entities_pickable()
		"NPCs":
			set_tool("entity", "npc")
			set_entities_pickable()
		"Triggers":
			set_tool("entity", "trigger")
			set_entities_pickable()
		_:
			print("WARNING: could not find tab with name: " + $Main/Tab.get_child(tab).name)


