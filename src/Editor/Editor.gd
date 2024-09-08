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
const TILE_MAP_CURSOR = preload("res://src/Editor/TileMapCursor.tscn")


var disabled = false

var brush = {} #2D array THIS IS BRUSH
var tile_map_selection: Rect2
var auto_layer = true
var multi_erase = true
var auto_tile = true

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


@onready var w = get_tree().get_root().get_node("World")
@onready var ui = w.get_node("UILayer")
@onready var el = w.get_node("EditorLayer")
@onready var inspector = $Secondary/Win/Inspector
@onready var tile_master = $TileMaster
var tile_collection
var actor_collection
var prop_collection
var trigger_collection
var tile_map
var tile_set
var editor_level_limiter
var tile_map_cursor


func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	_on_viewport_size_changed()
	connect("tile_collection_selected", Callable(inspector, "on_selected").bind("tile_collection"))
	connect("level_selected", Callable(inspector, "on_selected").bind("level"))
	el.add_child(EDITOR_CAMERA.instantiate())
	
	setup_level() #Call this every time the level is changed or reloaded
	#$Main/Win.move_child($Main/Win/Tab, 0) TODO: was supposed to make tabcontainer go behind resize controls, didnt work

func setup_level(): #TODO: clear undo history
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
	tile_master.setup_tile_master()
	$Main/Win/Tab/TileSet.load_tile_set(tile_set.resource_path)
	



	setup_level_editor_layer()
	set_entities_pickable()
	w.set_debug_visible(true)
	move_actors_to_home()
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		s.visible = true
	for l in get_tree().get_nodes_in_group("SunLights"):
		l.editor_enter()
	for t in trigger_collection.get_children():
		if t.has_node("TriggerController"):
			t.get_node("TriggerController").enable()
	el.get_node("EditorCamera").make_current()
	

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


func setup_level_editor_layer(): #the layer for editor overlays that go over the level
	var editor_layer = Node2D.new()
	editor_layer.name = "Editor"
	editor_layer.z_index = 8
	w.current_level.add_child(editor_layer)
	editor_level_limiter = LIMITER.instantiate()
	editor_layer.add_child(editor_level_limiter)
	tile_map_cursor = TILE_MAP_CURSOR.instantiate()
	editor_layer.add_child(tile_map_cursor)


###

func load_editor_windows():
	pass


func exit():
	#get_tree().paused = false
	inspector.exit()
	
	hide_preview() #delete tile brush preview
	editor_level_limiter.queue_free()
	el.get_node("EditorCamera").queue_free()
	ui.add_child(HUD.instantiate())
	w.get_node("Juniper").enable()
	w.get_node("Juniper/PlayerCamera").enabled = true
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
	for t in trigger_collection.get_children():
		if t.has_node("TriggerController"):
			t.get_node("TriggerController").disable()

### PROCESS ###

func _physics_process(_delta):
	set_menu_alpha()

### TILES




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
		if event.keycode == KEY_Z:
			if shift_held: redo()
			else: undo()
		if event.keycode == KEY_S:
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
	await get_tree().process_frame #wait for new active to be set
	
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
					set_entity(grid_pos, $Main/Win/Tab/Enemies.active_enemy_path, subtool) #subtool == "enemy"
			"prop":
				set_entity(grid_pos, $Main/Win/Tab/Props.active_prop_path, subtool)
			"npc":
				set_entity(grid_pos, $Main/Win/Tab/NPCs.active_npc_path, subtool)
			"trigger":
				set_entity(get_grid_pos(mouse_pos, "course", "trigger"), $Main/Win/Tab/Triggers.active_trigger_path, subtool)
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
					preview_entity(grid_pos, $Main/Win/Tab/Enemies.active_enemy_path, subtool)
			"prop":
				preview_entity(grid_pos, $Main/Win/Tab/Props.active_prop_path, subtool)
			"npc":
				preview_entity(grid_pos, $Main/Win/Tab/NPCs.active_npc_path, subtool)
			"trigger":
				preview_entity(get_grid_pos(mouse_pos, "course", "trigger"), $Main/Win/Tab/Triggers.active_trigger_path, subtool)
			"grab":
				inspector.active.global_position = grid_pos + grab_offset
				if "home" in inspector.active:
					inspector.active.home = inspector.active.global_position
	
	#deleting
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_DELETE: #or event.keycode == KEY_BACKSPACE or (event.keycode == KEY_X and not ctrl_held)
			if inspector.active:
				if not(inspector.active_type == "background" or inspector.active_type == "spawn_point"):
					inspector.active.queue_free()
					inspector.on_deselected()





func do_tile_input(event):
	pass
	#var mouse_pos = w.get_global_mouse_position()
	#
	#if lmb_held: pass #brush = brush
	#if rmb_held: pass#brush = get_brush_as_eraser()
	#
	#if event.is_action_pressed("debug_fly"):
		#print(active_operation)
		#if auto_tile:
			#print("auto tiling")
			#set_auto_tiles() #TODO: testing
#
	#
	##pressing
	#if event.is_action_pressed("editor_rmb") or event.is_action_pressed("editor_lmb"):
		#mouse_start_pos = mouse_pos
		#if subtool == "select":
			#if event.is_action_pressed("editor_lmb"):
				#set_tile_map_selection(mouse_start_pos, mouse_pos)
##			if event.is_action_pressed("editor_rmb"):
##				move_tile_map_selection("mou")
		#else: #not brush.is_empty(): #normal draw              #TODO:WHY
			#if shift_held: set_tool("tile", "line")
			#elif ctrl_held: set_tool("tile", "box")
			#else: 
				#set_tool("tile", "paint")
				#set_cells_2d(get_centerbox(mouse_pos), brush) #TODO: on all layers
	#
	##moving
	#if event is InputEventMouseMotion:
		#hide_preview()
		#match subtool:
			#"select":
				#if lmb_held:
					#set_tile_map_selection(mouse_start_pos, mouse_pos)
			#"line":
				##preview_tiles(get_brush_origin_line(mouse_start_pos, mouse_pos), "line")
				#pass
			#"box":
				#pass
				##preview_tiles(get_box_2d_array(mouse_start_pos, mouse_pos), "box")
			#"paint":
				#if lmb_held or rmb_held:
					#set_cells_2d(get_centerbox(mouse_pos), brush) #TODO: on all layers
				#else:
					#pass
					##preview_tiles(get_centerbox(mouse_pos), "box")
	#
	##releasing
	#if event.is_action_released("editor_lmb") and lmb_held or event.is_action_released("editor_rmb") and rmb_held:
		#match subtool:
			#"select":
				#if rmb_held:
					#move_tile_map_selection(mouse_start_pos, mouse_pos)
			#"line":
				#set_line(get_brush_origin_line(mouse_start_pos, mouse_pos), brush) #TODO: on all layers
			#"box":
				#if lmb_held:
					#set_cells_2d_array(get_box_2d_array(mouse_start_pos, mouse_pos), brush)
				#elif rmb_held:
					#pass
					##set_cells_2d_array(get_box_2d_array(mouse_start_pos, mouse_pos), get_brush_as_eraser())
					##set_cells_1d(get_box_1d(mouse_start_pos, mouse_pos), -1)
				#
		#if subtool != "select":
			#subtool = "paint"
		#if not active_operation.is_empty():
			#past_operations.append(["set_cells", active_operation.duplicate()])
			##print("active op: ", active_operation)
			#active_operation.clear()
		#
		#if auto_tile:
			#print("auto tiling")
			#set_auto_tiles() #TODO: testing



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

func set_tile_map_selection(start_pos, end_pos):
	tile_map_selection = Rect2(get_cell(start_pos), Vector2.ZERO)
	tile_map_selection = tile_map_selection.expand(get_cell(end_pos))
	tile_map_selection.size += Vector2.ONE
	tile_map_cursor.position = tile_map_selection.position * 16
	tile_map_cursor.size = tile_map_selection.size * 16
	#print(tile_map_selection)

func move_tile_map_selection(start_pos, end_pos):# TODO: make work with undo/redo
	var selected_tiles = get_selected_tiles_as_dictionary()
	
	var change = get_cell(end_pos) - get_cell(start_pos)
	tile_map_selection.position += change
	tile_map_cursor.position = tile_map_selection.position * 16
	tile_map_cursor.size = tile_map_selection.size * 16

	set_selected_tiles_from_dictionary(selected_tiles, change)

func del_tile_map_selection(): #TODO: test
	var selected_tiles = get_selected_tiles_as_dictionary()
	
	for layer in selected_tiles:
		for pos in selected_tiles[layer]:
			layer.set_cellv(pos, -1)


func get_selected_tiles_as_dictionary() -> Dictionary: #used for tile map selection
	var selected_tiles = {}
	for layer in tile_collection.get_children():
		var layer_tiles = {}
		for row in tile_map_selection.size.y:
			for column in tile_map_selection.size.x:
				var pos = tile_map_selection.position + Vector2(column, row)
				layer_tiles[pos] = layer.get_cell_source_id(0, position)
		selected_tiles[layer] = layer_tiles
	return(selected_tiles)


func set_selected_tiles_from_dictionary(selected_tiles, change): #used for tile map selection
	for layer in selected_tiles:
		for pos in selected_tiles[layer]:
			var map_position = pos + change
			var tile_id = selected_tiles[layer][pos]
			layer.set_cellv(pos, -1)
			layer.set_cellv(map_position, tile_id)
#			if tile_id != -1:
#				print("got tile")

func undo():
	var last = past_operations.pop_back()

	if last:
		future_operations.append(last)
		#print("undoing operation: ", last)

		match inspector.active_type: #get rid of selection to prevent time travel paradoxes
			"enemy", "npc", "prop":
				inspector.on_deselected()


		match last[0]: #["operation_name", [subop1], [subop2], [
			"set_cells":
				var subops = last[1]
				subops.invert()
				for t in subops: #subop = [layer: object, position, tile, old_tile (dict or int)
					var old_tile = t[3]
					if old_tile is int:
						var layer = t[0]
						var cell_pos = t[1]
						var new_tile = t[2]
						set_cell(cell_pos, old_tile, layer)
					
					elif old_tile is Dictionary :#old_tile = {layer: [cell, tile]}
						for layer in old_tile:
							var cell_pos = old_tile[layer][0]
							var layer_old_tile = old_tile[layer][1]
							set_cell(cell_pos, layer_old_tile, layer)
		
			"set_entity":
				var arg = last[1]
				del_entity(arg[0], false) #position, traced
	else:
		print("nothing left to undo!")

func redo():
	pass
#	var next = future_operations.pop_back()
#
#	if next:
#		past_operations.append(next)
#		print("redoing operation: ", next)
#
#		match next[0]:
#			"set_tiles_1d":
#				var subops = next[1]
#				subops.invert()
#				for t in subops:
#					var cell_pos = t[0]
#					var tile = t[1]
#					set_cells_1d(cell_pos, tile)
#					#set_cells_1d([t[0]], t[1], t[3], false) #pos_array, new_tile, layer, traced
#			"set_entity":
#				var arg = next[1]
#				set_entity(arg[0], arg[1], arg[2], false) #position, entity_path, entity_type
#	else:
#		print("nothing left to redo!")


func set_cell(cell: Vector2, tile: int, layer): #set one cell, one layer, one tile ##ONLY VIA UNDO/REDO
	if tile == -2: #null
		return
	layer.set_cellv(cell, tile)



#func set_cells_1d(cells: Array, tile, traced = true): #sets a 1d array of cells with a single tile
#	if tile == -2: #null
#		return
#
#	var old_tile_dic = {} # layer: [[cell, tile][cell, tile][cell, tile]]
#	for layer in tile_collection.get_children():
#		if layer is TileMap:
#			old_tile_dic[layer] = []
#
#	for cell in cells: #subops
#
#		var layer = tile_map
#		if auto_layer and not tile == -1: #not eraser and auto layer
#			layer = get_auto_layer(tile)
#		if multi_erase and tile == -1: #eraser
#			for l in tile_collection.get_children():
#				if l is TileMap:
#
#					if l.get_cell_source_id(0, cell) == tile: #if old tile == new tile
#						pass
#					else:
#						old_tile_dic[l].append([cell, l.get_cell_source_id(0, cell)])
#						l.set_cellv(cell, tile)
#		else: #not multi_eraser
#			if layer.get_cell_source_id(0, cell) == tile: #if old tile == new tile
#				pass
#			else:
#				old_tile_dic[layer].append([cell, layer.get_cell_source_id(0, cell)])
#				layer.set_cellv(cell, tile)
#
#	if traced:
##		for s in active_operation:
##			if s[0] == cell: #already setting this cell in the current operation, this prevents reactivating on mouse movement
##				return
#		active_operation.append([cells, tile, old_tile_dic])
#		#print(active_operation)


func set_cells_dictionary(cells: Dictionary, brush: Dictionary): #ex: {layerobject1:{Vector2(0,0): -1, Vector2(0,1): 1}}
	var min_pos = Vector2(9999, 9999)
	var brush_size = Vector2(0, 0)
	
	for layer in cells:
		for pos in cells[layer]:
			if pos.x < min_pos.x or (pos.x == min_pos.x and pos.y < min_pos.y):
				pos = min_pos
	
	for layer in brush:
		for pos in brush[layer]:
			if pos.x > brush_size.x or (pos.x == brush_size.x and pos.y > brush_size.y):
				pos = brush_size
				
	for layer in cells:
		for pos in cells[layer]:
			
			var brush_pos = (pos - min_pos) % brush_size
			var tile_id = brush[layer][brush_pos]
			layer.set_cellv(pos, tile_id)
		
	
func set_cells_2d_array(cells: Dictionary, brush: Dictionary, traced = true):
	var brush_size = get_brush_size()
	for b_layer in brush:
		if not brush[b_layer].is_empty(): #if layer is not empty
			var layer_id = b_layer
			var layer = cells[layer_id]
			for row in layer:
				for cell in row:
					var tile = brush[b_layer][layer.find(row) % int(brush_size.y)][row.find(cell) % int(brush_size.x)]
					b_layer.set_cellv(cell, tile) #TODO: add empty rows, add empty tiles, skip nonexistant rows, change brush size calulation to only consider x layer
		
	
func set_cells_2d(cells: Array, brush: Array, traced = true): #There is no reason we need a 2d array of cells. cells have their positions already
	#if brush.empty(): return
	
	
	
	var r_id = 0
	var r_max = brush.size()
	for row in cells:
		var c_id = 0
		var c_max = brush[c_id].size()
		for cell in row: #subops
			
			var tile = brush[r_id % r_max][c_id % c_max] # % so it repeats if cells > tiles
			if tile == -2: pass #null
				
			var old_tile
			var layer = tile_map
			var is_eraser = brush == get_brush_as_eraser() #this works as long as nobody added an arguement to get_brush_as_eraser
			
			
			if multi_erase and is_eraser:
				print("multi erase toggled")
				old_tile = {}
				for l in tile_collection.get_children():
					if l is TileMap and not l.is_in_group("Previews"):
						var replaced_tile = l.get_cell_source_id(0, cell) #get old tile
						if replaced_tile != -1: #if this layer actually had tiles replaced
							old_tile[l] = [cell, replaced_tile]
							l.set_cellv(cell, tile) #set new tile (eraser == -1)


			if auto_layer and not is_eraser: #if auto layer is on, still use the current layer as the eraser
				layer = get_auto_layer(tile)
				old_tile = layer.get_cell_source_id(0, cell) #get old tile
				layer.set_cellv(cell, tile) #set new tile


			if traced:
				for s in active_operation:
					if s[1] == cell and s[2] == tile: #already setting this cell in the current operation, this prevents reactivating on mouse movement
						return
				active_operation.append([layer, cell, tile, old_tile])



			c_id += 1
		r_id += 1


func set_line(canvas: Array, brush: Array, traced = true):
	if brush.is_empty():
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
						
						var old_tile
						var layer = tile_map
						if auto_layer:
							layer = get_auto_layer(tile)
						
						if multi_erase and brush == get_brush_as_eraser(): #this works as long as nobody added an arguement to get_brush_as_eraser
							old_tile = {}
							for l in tile_collection.get_children():
								if l is TileMap and not l.is_in_group("Previews"):
									var replaced_tile = l.get_cell_source_id(0, cell + offset) #get old tile
									if replaced_tile != -1: #if this layer actually had tiles replaced
										old_tile[l] = [cell + offset, replaced_tile] 
									l.set_cellv(cell + offset, tile) #set_new_tile
						
						
						else: #not eraser
							old_tile = layer.get_cell_source_id(0, cell + offset) #get_old_tile
							layer.set_cellv(cell + offset, tile)
						
						if traced:
#							if s[1] == cell and s[2] == tile: #already setting this cell in the current operation, this prevents reactivating on mouse movement
#								return
							
							if multi_erase and brush == get_brush_as_eraser():
								active_operation.append([layer, cell + offset, tile, old_tile])
							else:
								active_operation.append([layer, cell + offset, tile, old_tile])
								
								active_operation.append([layer, cell, tile, old_tile])
					
					brush_c_id += 1
				brush_r_id +=1
			c_id += 1
		r_id += 1


func set_auto_tiles():
	var script_path = "res://src/Tile/%s.gd"
	var auto_tile_script = load(script_path % tile_set.resource_path.get_file().trim_suffix(".tres")) #get tile set's name and find corresponding script
	var node = Node.new()
	
	if auto_tile_script:
		node.set_script(auto_tile_script)
		node.farback = tile_collection.get_node("FarBack")
		node.back = tile_collection.get_node("Back")
		node.front = tile_collection.get_node("Front")
		node.farfront = tile_collection.get_node("FarFront")
		add_child(node)

func set_entity(pos, entity_path, entity_type, traced = true):
	if entity_path == null:
		printerr("ERROR: no enemy path in set_entity")
	
	var entity = load(entity_path).instantiate()
	if entity.has_method("disable"):
		entity.disable()
	entity.global_position = pos
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

func del_entity(pos, traced = true):
		for e in get_tree().get_nodes_in_group("Entities"):
			if is_entity_at_position(e, pos):
				e.queue_free()





### PREVIEW ###


func preview_tiles(cells: Array, type = "box"): #2D array of cells
	for m in tile_collection.get_children():
		if m.is_in_group("Previews"):
			m.queue_free()
	
	var tile_map = TileMap.new()
	tile_map.add_to_group("Previews")
	tile_map.tile_set = tile_set
	tile_map.cell_size = Vector2(16, 16)
	tile_map.modulate = Color(1, 1, 1, 0.5)
	tile_map.z_index = 999
	tile_collection.add_child(tile_map)
	
	match type:
		"box": set_preview_box(cells, tile_map)
		"line": set_preview_line(cells, tile_map)


func set_preview_box(cells, tile_map):
	var r_id = 0
	var r_max = brush.size()
	for row in cells:
		var c_id = 0
		var c_max = brush[c_id].size()
		for cell in row:
			var tile = brush[r_id % r_max][c_id % c_max] # % so it repeats if cells > tiles
			
			tile_map.set_cellv(cell, tile)
			c_id += 1
		r_id += 1


func set_preview_line(cells: Array, tile_map):
	var r_id = 0
	var r_max = brush.size()
	for row in cells:
		var c_id = 0
		var c_max = brush[c_id].size()
		for cell in row:
			
			var br_id = 0
			for b_row in brush:
				var bc_id = 0
				for b_cell in b_row:
					var tile = b_cell
					var offset = Vector2(bc_id, br_id)
					tile_map.set_cellv(cell + offset, tile)
					bc_id += 1
				br_id +=1
			c_id += 1
		r_id += 1



func preview_entity(pos, entity_path, entity_type):
	var preview = ENTITY_PREVIEW.instantiate()
	preview.entity_type = entity_type
	preview.entity_path = entity_path
	preview.global_position = pos
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
		if c is Sprite2D:
			c.queue_free()
	for e in get_tree().get_nodes_in_group("Previews"):
		e.queue_free()



### GETTERS ###


func get_cell(mouse_pos) -> Vector2:
	var local_pos = tile_map.to_local(mouse_pos)
	var map_pos = tile_map.local_to_map(local_pos)
	return map_pos

func get_grid_pos(mouse_pos, mode = "course", exception = "none") -> Vector2:
	var step = 16
	var offset = Vector2(8,0)
	if mode == "fine":
		step = 8
		offset = Vector2(0, 0)
	if exception == "trigger":
		return Vector2(snapped(mouse_pos.x, step), snapped(mouse_pos.y, step))
	else:
		return Vector2(snapped(mouse_pos.x - offset.x, step), snapped(mouse_pos.y - offset.y, step)) + offset


func get_centerbox(mouse_pos) -> Array: #2D Array #active tiles
	var cells = []
	var b = get_brush_size()
	
	var center = Vector2(floor(b.x/2), floor(b.y/2))
	var center_cell = get_cell(mouse_pos)
	#assumes an odd number
	for row in b.y:
		var row_cells = []
		for cell in b.x:
			var offset = Vector2(cell - center.x, row - center.y)
			row_cells.append(center_cell + offset) #position of cell in map space
		if not row_cells.is_empty():
			cells.append(row_cells)
	return cells


#func get_box_1d(start_pos, end_pos) -> Array: #1d
#	var cells = []
#	var start = get_cell(start_pos)
#	var end = get_cell(end_pos)
#	var x_min = min(start.x, end.x)
#	var x_max = max(start.x, end.x)
#	var y_min = min(start.y, end.y)
#	var y_max = max(start.y, end.y)
#
#	for y in range(y_min, y_max + 1):
#		for x in range(x_min, x_max + 1):
#			cells.append(Vector2(x, y))
#	#print(cells)
#	return cells


#func get_box_2d(start_pos, end_pos) -> Array:#PoolVector2Array: #2d #TODO: massive slowdown when drawing bigger boxes. memory leak.
#	var cells = []#PoolVector2Array()
#	var start = get_cell(start_pos)
#	var end = get_cell(end_pos)
#	var x_min = min(start.x, end.x)
#	var x_max = max(start.x, end.x)
#	var y_min = min(start.y, end.y)
#	var y_max = max(start.y, end.y)
#
#	for y in range(y_min, y_max + 1):
#		var row = []
#		for x in range(x_min, x_max + 1):
#			row.append(Vector2(x, y))
#		cells.append(row)
#	#print(cells)
#	return cells

func get_box_2d_array(start_pos, end_pos) -> Dictionary:
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var x_min = min(start.x, end.x)
	var x_max = max(start.x, end.x)
	var y_min = min(start.y, end.y)
	var y_max = max(start.y, end.y)
	
	var cells = {}
	for layer in tile_collection.get_children():
		if layer is TileMap:
			cells[layer] = []
			for y in range(y_min, y_max + 1):
				var row = []
				for x in range(x_min, x_max + 1):
					row.append(Vector2(x, y))
				cells[layer].append(row)
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
	var b = get_brush_size()
	
	if abs(dx) >= (b.x/b.y) * abs(dy): #TODO: this division seems to slow down the game with very tall brushes #May be fixed, check
		for x in range(x_min, x_max+1):
			if x % b.x == 0: #start of a brush
				var y = round(start.y + dy * (x - start.x) / dx)
				cells.append(Vector2(x, y))
	
	else:
		for y in range(y_min, y_max+1):
			if y % b.y == 0: #start of a brush 
				var x = round(start.x + dx * (y - start.y) / dy)
				cells.append(Vector2(x, y))
	
	return get_2d_array_from_Vector2_array(cells)



### HELPER GETTERS ###

func get_brush_size() -> Vector2:
	var brush_size = Vector2.ZERO
	brush_size.y = brush.size()
	for layer in brush:
		for row in brush[layer]:
			if row.size() > brush_size.x:
				brush_size.x = row.size()
	return brush_size


func get_brush_as_eraser(null_erase = true) -> Array: #erase with null tiles by default
	var eraser = []
	for row in brush:
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


func is_entity_at_position(entity, pos, forgiveness = 4):
	var out = false
	if abs(pos.x - entity.global_position.x) < forgiveness and abs(pos.y - entity.global_position.y) < forgiveness:
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

### UI ###
func set_menu_alpha():
	var mouse_pos = get_global_mouse_position()
	var main_rect = Rect2($Main/Win.position, $Main/Win.size)
	var secondary_rect = Rect2($Secondary/Win.position, $Secondary/Win.size)
	if main_rect.has_point(mouse_pos):
		$Main.self_modulate = Color(1, 1, 1, 1)
	else:
		$Main.self_modulate = Color(1, 1, 1, 0.50)
	if secondary_rect.has_point(mouse_pos):
		$Secondary.self_modulate = Color(1, 1, 1, 1)
	else:
		$Secondary.self_modulate = Color(1, 1, 1, 0.50)




### SIGNALS ###



### TILES SIGNALS

#func on_terrain_toggled(toggle): #DEBUG
#	create_tile_set_from_texture(load("res://assets/Tile/VillageTerrain.png"))

func _on_Tiles_tile_transform_updated(tile_rotation_degrees, tile_scale_vector):
	pass # Replace with function body. #TODO move to tiles code




### MISC SIGNALS

func _on_viewport_size_changed():
	await get_tree().process_frame
	#$Margin.size = get_tree().get_root().size / Vector2i(w.get_node("EditorLayer").scale)
	$Margin.size = Vector2(get_tree().get_root().size) / Vector2(w.get_node("EditorLayer").scale)
	#size = get_tree().get_root().size / Vector2i(w.get_node("EditorLayer").scale)

func on_tab_selected(tab_index): #tab buttons
	$Main/Win/Tab.current_tab = tab_index

func on_tab_changed(tab):
	match $Main/Win/Tab.get_child(tab).name:
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
			print("WARNING: could not find tab with name: " + $Main/Win/Tab.get_child(tab).name)
