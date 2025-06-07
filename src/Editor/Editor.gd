extends Control

#signal enemy_selected(enemy)
#signal prop_selected(prop)
#signal entity_selected(entity, entity_type)
signal level_selected(level)
signal layer_updated(active_tile_map_layer)

signal level_saved()
signal tab_changed(tab_name)

const ACTOR_SPAWN = preload("res://src/Editor/ActorSpawn.tscn")
const ACTOR_SPAWN_PREVIEW = preload("res://src/Editor/ActorSpawnPreview.tscn")
const EDITOR_CAMERA = preload("res://src/Editor/EditorCamera.tscn")
#const ENTITY_PREVIEW = preload("res://src/Editor/EntityPreview.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const LAYER_BUTTON = preload("res://src/Editor/Button/LayerButton.tscn")
const LIMITER = preload("res://src/Editor/EditorLevelLimiter.tscn")
const TILE_MAP_CURSOR = preload("res://src/Editor/TileMapCursor.tscn")
const TILE_MAP_PREVIEW = preload("res://src/Editor/TileMapPreview.tscn")
const TRIGGER_SPAWN = preload("res://src/Editor/TriggerSpawn.tscn")


var disabled = false

var brush #Rect2i
var tile_map_selection: Rect2i
var tile_map_copy_buffer: Dictionary
var active_tile_map_layer: int = 0
var multi_erase = false
var auto_tile = true

var active_tool = "tile"
var subtool = "paint"
var mouse_start_pos
var grab_offset = Vector2()
var pre_grab_tool: String
var pre_grab_subtool: String
var last_updated_cell: Vector2i #store for limiting updating cells on mousing over with a tool, i.e. painting
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
@onready var log = $Margin/Log
var actor_collection
var prop_collection
var trigger_collection
var spawn_collection
var tile_map
var editor_level_limiter
var tile_map_cursor

### SETUP ###

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	_on_viewport_size_changed()
	#connect("tile_map_selected", Callable(inspector, "on_selected").bind("tile_map"))
	connect("level_selected", Callable(inspector, "on_selected").bind("level"))
	el.add_child(EDITOR_CAMERA.instantiate())
	
	setup_level() #Call this every time the level is changed or reloaded
	#$Main/Win.move_child($Main/Win/Tab, 0) TODO: was supposed to make tabcontainer go behind resize controls, didnt work

func setup_level(): #TODO: clear undo history
	#emit_signal("level_selected", w.current_level)
	setup_windows()
	w.get_node("Juniper").disable()
	ui.get_node("HUD").queue_free()
	ui.visible = false
	for a in get_tree().get_nodes_in_group("Actors"):
		a.queue_free()
	for t in get_tree().get_nodes_in_group("Triggers"):
		t.queue_free()
	actor_collection = w.current_level.get_node("Actors")
	prop_collection = w.current_level.get_node("Props")
	trigger_collection = w.current_level.get_node("Triggers")
	spawn_collection = w.current_level.get_node("Spawns")
	
	tile_map = w.current_level.get_node("TileMap")
	tile_master.setup_tile_master()
	$Main/Win/Tab/TileSet.load_tile_set(tile_map.tile_set.resource_path)
	if w.current_level.has_node("TileAnimator"):
		w.current_level.get_node("TileAnimator").editor_enter()
	
	$Main/Win/Tab/Levels.setup_levels()
	$Main/Win/Tab/Triggers.setup_triggers()
	
	setup_level_editor_layer()
	#set_entities_pickable()
	for s in get_tree().get_nodes_in_group("SpawnPoints"): #TODO: see if you can avoid this by calling a signal or something
		s.visible = true
	for a in get_tree().get_nodes_in_group("ActorSpawns"):
		a.visible = true
		a.input_pickable = true
	for t in get_tree().get_nodes_in_group("TriggerSpawns"):
		t.visible = true
	for l in get_tree().get_nodes_in_group("SunLights"):
		l.editor_enter()
	for t in trigger_collection.get_children():
		if t.has_node("TriggerController"):
			t.get_node("TriggerController").enable()
	el.get_node("EditorCamera").make_current()
	w.current_level.get_node("LevelLimiter").setup() #must be after camera setup
	

func setup_windows(): #the main and secondary editor windows
	await get_tree().process_frame
	$Main/Win.size = $Margin/VBox/HBox/MainSizeRef.size
	$Main/Win.position = $Margin/VBox/HBox/MainSizeRef.position
	$Secondary/Win.size = $Margin/VBox/HBox/SecondarySizeRef.size
	$Secondary/Win.position = $Margin/VBox/HBox/SecondarySizeRef.position

#func set_entities_pickable(pickable = true): #TODO: this is still used, move away from this with the new dummy actorspawns
	#for a in actor_collection.get_children():
		#if not a.is_in_group("Previews"):
			#a.input_pickable = pickable
	#for p in prop_collection.get_children():
		#if not p.is_in_group("Previews"):
			#p.input_pickable = pickable
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




func exit():	#TODO: make this an editor_exit signal ## no? that just decentralizes and makes the order that this triggers in unclear. the order is important!
	inspector.exit()
	if w.current_level.has_node("TileAnimator"):
		w.current_level.get_node("TileAnimator").editor_exit()
	clear_tile_map_cursor()
	free_previews()
	editor_level_limiter.queue_free()
	el.get_node("EditorCamera").queue_free()
	ui.add_child(HUD.instantiate())
	ui.visible = true
	mc.display("arrow")
	w.get_node("Juniper").enable()
	w.get_node("Juniper/PlayerCamera").enabled = true
	w.get_node("Juniper/PlayerCamera").make_current()
	w.current_level.get_node("LevelLimiter").setup() #must be after camera setup
	#set_entities_pickable(false)
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		s.visible = false
	for a in get_tree().get_nodes_in_group("ActorSpawns"):
		a.spawn()
		a.visible = false
	for t in get_tree().get_nodes_in_group("TriggerSpawns"):
		t.spawn()
		t.visible = false
	for l in get_tree().get_nodes_in_group("SunLights"):
		l.editor_exit()
	queue_free()
	for t in trigger_collection.get_children():
		if t.has_node("TriggerController"):
			t.get_node("TriggerController").disable()



### PROCESS ###

func _physics_process(_delta):
	set_menu_alpha()






### TILES ###
#
#func get_tile_texture(tile):
	#var tile_texture = AtlasTexture.new()
	#tile_texture.atlas = tile_set.tile_get_texture(tile)
	#tile_texture.region = tile_set.tile_get_region(tile)
	#return tile_texture


### INPUT ###

func _unhandled_input(event):
	if disabled:
		return
	
	if event.is_action_pressed("editor_ctrl"): ctrl_held = true
	if event.is_action_released("editor_ctrl"): ctrl_held = false
	if event.is_action_pressed("editor_shift"): shift_held = true
	if event.is_action_released("editor_shift"): shift_held = false


	if event is InputEventKey and event.is_pressed() and not event.is_echo() and ctrl_held:
		match event.keycode:
			KEY_C:
				copy_tile_map_selection()
			KEY_V:
				var pos: Vector2i = get_cell(w.get_global_mouse_position())
				paste_tiles_from_buffer(pos)
			KEY_Z:
				if shift_held: redo()
				else: undo()
			KEY_S:
				emit_signal("level_saved")


	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_F1: on_tab_selected(0)
			KEY_F2: on_tab_selected(1)
			KEY_F3: on_tab_selected(2)
			KEY_F4: on_tab_selected(3)
			KEY_F5: on_tab_selected(4)
			KEY_F6: on_tab_selected(5)
			KEY_F7: on_tab_selected(6)
	
	
	if event.is_action_pressed("editor_lmb"):
		lmb_held = true
		rmb_held = false #this might fuck things up for other tools
		future_operations.clear()

	if event.is_action_pressed("editor_rmb"):
		rmb_held = true
		inspector.on_deselected() #slight consequence is in inspector, unsaved values will reset on moving entity
		#lmb_held = false #this might fuck things up for other tools
		future_operations.clear()

	#main part
	await get_tree().process_frame #wait for new active to be set
	match active_tool:
		"tile": do_tile_input(event)
		"entity": do_entity_input(event)
	do_generic_input(event)
	
	#after, just so we can check held during main part
	if event.is_action_released("editor_lmb"):
		lmb_held = false
	if event.is_action_released("editor_rmb"):
		rmb_held = false



func do_tile_input(event):
	var mouse_pos = w.get_global_mouse_position()

	#pressing
	if event.is_action_pressed("editor_rmb") or event.is_action_pressed("editor_lmb"):
		last_updated_cell = tile_map.local_to_map(tile_map.to_local(mouse_pos))
		mouse_start_pos = mouse_pos
		if subtool == "select":
			if event.is_action_pressed("editor_lmb"):
				set_tile_map_selection(mouse_start_pos, mouse_pos)
			if event.is_action_pressed("editor_rmb"):
				mc.display("grabclosed")
		elif brush: #normal draw
			if shift_held: set_tool("tile", "line")
			elif ctrl_held: set_tool("tile", "box")
			else: 
				set_tool("tile", "paint")
				if event.is_action_pressed("editor_lmb"):
					set_cells(get_cells_centerbox(mouse_pos))
				elif event.is_action_pressed("editor_rmb"):
					if inspector.active and inspector.active_type != "background" and inspector.active_type != "tile_map":
						return #don't erase a tile if we're selecting an entity
					set_cells(get_cells_centerbox(mouse_pos), true)
					mc.display("eraser")
	
	#moving
	if event is InputEventMouseMotion:
		var new_updated_cell = tile_map.local_to_map(tile_map.to_local(mouse_pos)) 
		if new_updated_cell != last_updated_cell: #don't trigger if we haven't moved a cell over
			#print("moved a cell over")
			last_updated_cell = new_updated_cell #update
			free_previews()
			match subtool:
				"select":
					if lmb_held:
						set_tile_map_selection(mouse_start_pos, mouse_pos)
					if rmb_held:
						preview_move_tile_set_selection(mouse_start_pos, mouse_pos)
				"line":
					preview_cells_line(get_cells_line_origins(mouse_start_pos, mouse_pos))
				"box":
					preview_cells_box(get_cells_box(mouse_start_pos, mouse_pos))
				"paint":
					if not brush:
						return
					if lmb_held:
						#TODO: group cells set by operation to ease undo code
						set_cells(get_cells_centerbox(mouse_pos))
					elif rmb_held:
						set_cells(get_cells_centerbox(mouse_pos), true)
					else:
						preview_cells_box(get_cells_centerbox(mouse_pos))
	
	#releasing
	if event.is_action_released("editor_lmb") and lmb_held or event.is_action_released("editor_rmb") and rmb_held:
		last_updated_cell = Vector2i.ZERO
		match subtool:
			"select":
				if rmb_held:
					move_tile_map_selection(mouse_start_pos, mouse_pos)
					mc.display("grabopen")
			"line":
				set_cells_from_brush_origins(get_cells_line_origins(mouse_start_pos, mouse_pos))
			"box":
				if lmb_held:
					set_cells(get_cells_box(mouse_start_pos, mouse_pos))
				elif rmb_held:
					set_cells(get_cells_box(mouse_start_pos, mouse_pos), true)
				
		if subtool != "select": #why this way?
			subtool = "paint"
			if rmb_held:
				mc.display("brush")
			
		if not active_operation.is_empty():
			past_operations.append(["set_cells", active_operation.duplicate()])
			#print("active op: ", active_operation)
			active_operation.clear()
		
	#clearing tile
	if event.is_action_pressed("editor_delete"):
		erase_tile_map_selection()



func do_entity_input(event):
	var mouse_pos = w.get_global_mouse_position() #Vector2(w.get_global_mouse_position().x, w.get_global_mouse_position().y + 8)
	var grid_pos = get_cell(mouse_pos)

	#placing
	if event.is_action_pressed("editor_lmb"):
		if grid_pos_has_entity(grid_pos):
			am.play("ui_deny")
			return
		
		match subtool:
			"enemy":
				set_actor_spawn($Main/Win/Tab/Enemies.active_enemy_path, grid_pos)
			"prop":
				pass
			"npc":
				set_actor_spawn($Main/Win/Tab/NPCs.active_npc_path, grid_pos)
			"trigger":
				set_trigger_spawn($Main/Win/Tab/Triggers.active_trigger_path, grid_pos)
			"noplace":
				pass


func do_generic_input(event):
	var mouse_pos = w.get_global_mouse_position() #Vector2(w.get_global_mouse_position().x, w.get_global_mouse_position().y + 8)
	var grid_pos = get_cell(mouse_pos)
	
	#grabbing entity
	if event.is_action_pressed("editor_rmb") and inspector.active:
		match inspector.active_type:
			"background", "tile_map": return
		pre_grab_tool = active_tool
		pre_grab_subtool = subtool
		set_tool("entity", "grab")
		grab_offset = inspector.active.global_position - mouse_pos

	#releasing entity
	if event.is_action_released("editor_rmb") and inspector.active:
		match inspector.active_type:
			"background", "tile_map": return
		set_tool(pre_grab_tool, pre_grab_subtool)

	#moving entity
	if event is InputEventMouseMotion:
		match subtool:
			"enemy":
				free_previews() #check that this doesnt clear on top of other inputs
				preview_actor_spawn($Main/Win/Tab/Enemies.active_enemy_path, grid_pos)
			"prop":
				pass
			"npc":
				free_previews()
				preview_actor_spawn($Main/Win/Tab/NPCs.active_npc_path, grid_pos)
			"trigger":
				pass
			"grab":
				if shift_held: inspector.active.global_position = Vector2(mouse_pos + grab_offset).snapped(Vector2(4,4))
				else: inspector.active.global_position = Vector2(mouse_pos + grab_offset).snapped(Vector2(8,8))
	
	#deleting entity
	if event.is_action_pressed("editor_delete"):
		if inspector.active:
			if not(inspector.active_type == "background" or inspector.active_type == "spawn_point"):
				inspector.active.queue_free()
				inspector.on_deselected()



#func get_entity_at_pos(position):
#	for a in actor_collection.get_children():
#		if a.position == position:
#			return a
#	for p in prop_collection.get_children():
#		if p.position == position:
#			return p
#	return null

#func get_entity_type(entity: Node): #called by actor.gd #TODO DONT DO THIS
	#if entity.is_in_group("ActorSpawns"): return "actor_spawn"
	#if entity.is_in_group("Props"): return "prop"
	#if entity.is_in_group("NPCs"): return "npc"
	#if entity.is_in_group("Triggers"): return "trigger"
	#if entity.is_in_group("SpawnPoints"): return "spawn_point"
	#
	#printerr("ERROR: Could not get entity type of entity: " + entity.name)
	#return null



### TILES ###

func set_tile_map_selection(start_pos, end_pos):
	tile_map_selection = Rect2i(get_cell(start_pos), Vector2i.ZERO)
	tile_map_selection = tile_map_selection.expand(get_cell(end_pos))
	tile_map_selection.size += Vector2i.ONE
	tile_map_cursor.position = (tile_map_selection.position * 16) - Vector2i(1, 1)
	tile_map_cursor.size = (tile_map_selection.size * 16) + Vector2i(2, 2)
	#print(tile_map_selection)

func move_tile_map_selection(start_pos, end_pos):# TODO: make work with undo/redo
	log.lprint("moved tiles")
	var selected_cells = get_selected_cells_as_dictionary()
	
	var change = get_cell(end_pos) - get_cell(start_pos)
	tile_map_selection.position += Vector2i(change)
	tile_map_cursor.position = (tile_map_selection.position * 16) - Vector2i(1, 1)
	tile_map_cursor.size = (tile_map_selection.size * 16) + Vector2i(2, 2)

	for layer in selected_cells:
		for cell in selected_cells[layer]:
			var old_tm_pos = cell[0]
			var new_tm_pos = cell[0] + change
			var ts_pos = cell[1]
			tile_map.set_cell(layer, old_tm_pos, -1, ts_pos) #erase old
			tile_map.set_cell(layer, new_tm_pos, 0, ts_pos)

func erase_tile_map_selection():
	log.lprint("erased tiles")
	var selected_cells = get_selected_cells_as_dictionary()
	for layer in selected_cells:
		for cell in selected_cells[layer]:
			var tm_pos = cell[0]
			var ts_pos = cell[1]
			tile_map.set_cell(layer, tm_pos, -1, ts_pos)


func copy_tile_map_selection():
	log.lprint("copied tiles")
	tile_map_copy_buffer = get_selected_cells_as_dictionary("local_to_selection")

func paste_tiles_from_buffer(pos):
	log.lprint("pasted tiles")
	for layer in tile_map_copy_buffer:
		for cell in tile_map_copy_buffer[layer]:
			var old_tm_pos = cell[0]
			var new_tm_pos = cell[0] + pos
			var ts_pos = cell[1]
			#tile_map.set_cell(layer, old_tm_pos, -1, ts_pos) #erase old
			tile_map.set_cell(layer, new_tm_pos, 0, ts_pos)
	

func get_selected_cells_as_dictionary(mode = "local_to_map") -> Dictionary: #used for tile map selection
	#{"layer 1": [[tm_pos1, ts_pos1], [tm_pos2, ts_pos2]],
	#"layer 2": ...}
	var selected_cells = {}
	
	for layer in tile_map.get_layers_count():
		var layer_cells = []
		for row in tile_map_selection.size.y:
			for column in tile_map_selection.size.x:
				var cell_pos = tile_map_selection.position + Vector2i(column, row)
				var tile_pos = tile_map.get_cell_atlas_coords(layer, cell_pos)
				if mode == "local_to_selection": #instead of local_to_map
					cell_pos = Vector2i(column, row)
				
				layer_cells.append([cell_pos, tile_pos])
	
		selected_cells[layer] = layer_cells
	return(selected_cells)






func undo():
	pass
	#var last = past_operations.pop_back()
#
	#if last:
		#future_operations.append(last)
		##print("undoing operation: ", last)
#
		#match inspector.active_type: #get rid of selection to prevent time travel paradoxes
			#"enemy", "npc", "prop":
				#inspector.on_deselected()
#
#
		#match last[0]: #["operation_name", [subop1], [subop2], [
			#"set_cells":
				#var subops = last[1]
				#subops.invert()
				#for t in subops: #subop = [layer: object, position, tile, old_tile (dict or int)
					#var old_tile = t[3]
					#if old_tile is int:
						#var layer = t[0]
						#var cell_pos = t[1]
						#var new_tile = t[2]
						#set_cell(cell_pos, old_tile, layer)
					#
					#elif old_tile is Dictionary :#old_tile = {layer: [cell, tile]}
						#for layer in old_tile:
							#var cell_pos = old_tile[layer][0]
							#var layer_old_tile = old_tile[layer][1]
							#set_cell(cell_pos, layer_old_tile, layer)
		#
			#"set_entity":
				#var arg = last[1]
				#del_entity(arg[0], false) #position, traced
	#else:
		#print("nothing left to undo!")

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
	pass
	#if tile == -2: #null
		#return
	#layer.set_cellv(cell, tile)



func set_cells(cells: Rect2i, erase = false): #no need to pass brush since its global
	var tile_map_layer: int
	for row in cells.size.y:
		for column in cells.size.x:
			var tile_set_position = Vector2i(column % brush.size.x, row % brush.size.y) + brush.position
			var tile_map_position = Vector2i(column, row) + cells.position
			tile_map_layer = get_tile_map_layer(tile_set_position.y)
			
			if erase:
				if multi_erase: #erase on all layers
					for layer in tile_map.get_layers_count():
						tile_map.set_cell(layer, tile_map_position, -1, tile_set_position)
				else: 
					tile_map.set_cell(active_tile_map_layer, tile_map_position, -1, tile_set_position)
			else:
				if tile_map.tile_set.get_source(0).has_tile(tile_set_position):
					tile_map.set_cell(tile_map_layer, tile_map_position, 0, tile_set_position) #draw
					if auto_tile and w.current_level.has_node("AutoTile"):
						w.current_level.get_node("AutoTile").do_auto_tile(tile_map_position, tile_map_layer)
			
			#If source_id is set to -1, atlas_coords to Vector2i(-1, -1) or alternative_tile to -1, the cell will be erased. An erased cell gets all its identifiers automatically set to their respective invalid values, namely -1, Vector2i(-1, -1) and -1.



func set_cells_from_brush_origins(origins: Array, erase = false):
	var tile_map_layer: int
	for origin in origins:
		for column in brush.size.x:
			for row in brush.size.y:
				var tile_set_position = Vector2i(column % brush.size.x, row % brush.size.y) + brush.position
				var tile_map_position = Vector2i(column, row) + origin
				tile_map_layer = get_tile_map_layer(tile_set_position.y)
				
				if erase:
					if multi_erase: #erase on all layers
						for layer in tile_map.get_layers_count():
							tile_map.set_cell(layer, tile_map_position, -1, tile_set_position)
					else:
						tile_map.set_cell(active_tile_map_layer, tile_map_position, -1, tile_set_position)
				else:
					tile_map.set_cell(tile_map_layer, tile_map_position, 0, tile_set_position) #draw



### ENTITIES ###

func set_actor_spawn(actor_path, pos):
	var actor_spawn = ACTOR_SPAWN.instantiate()
	actor_spawn.actor_path = actor_path
	actor_spawn.global_position = (pos * 16) + Vector2i(8, 16)
	spawn_collection.add_child(actor_spawn)
	actor_spawn.owner = w.current_level
	actor_spawn.initialize()
	inspector.on_selected(actor_spawn, "actor_spawn")

func set_trigger_spawn(trigger_path, pos):
	var trigger_spawn = TRIGGER_SPAWN.instantiate()
	trigger_spawn.trigger_path = trigger_path
	trigger_spawn.global_position = (pos * 16) + Vector2i(8, 16)
	#entity.input_pickable = true
	trigger_collection.add_child(trigger_spawn)
	trigger_spawn.owner = w.current_level
	trigger_spawn.initialize()
	inspector.on_selected(trigger_spawn, "trigger_spawn")
	

#func set_entity(pos, entity_path, entity_type, traced = true): #TODO: replace with custom per type, easier that way.
	#if entity_path == null:
		#printerr("ERROR: no enemy path in set_entity")
	#
	#var entity = load(entity_path).instantiate()
	#if entity.has_method("disable"):
		#entity.disable()
	#entity.global_position = pos
	#entity.input_pickable = true
	#
	#match entity_type:
		#"enemy", "npc", "player", "boss", "pickup":
			#actor_collection.add_child(entity)
		#"prop":
			#prop_collection.add_child(entity)
		#"trigger":
			##entity = TRIGGER_CONTROLLER.instance()
			#trigger_collection.add_child(entity)
		#_:
			#printerr("ERROR: cannot find entity_type: " + entity_type)
	#
	#entity.owner = w.current_level
	#if traced:
		#emit_signal("entity_selected", entity, entity_type) #select new entity
		#past_operations.append(["set_entity",[position, entity_path, entity_type]])

#func del_entity(pos, traced = true):
	#var forgiveness = 4
	#var selected_entities = []
	#for a in get_tree().get_nodes_in_group("ActorSpawns"):
		#selected_entities.append(a)
	#for e in selected_entities:
		#if abs(pos.x - e.global_position.x) < forgiveness and abs(pos.y - e.global_position.y) < forgiveness:
			#e.queue_free()





### PREVIEW ###

func preview_cells_box(cells: Rect2i):
	var tile_map_preview = setup_tile_map_preview()
	
	for row in cells.size.y:
		for column in cells.size.x:
			var tile_set_position = Vector2i(column % brush.size.x, row % brush.size.y) + brush.position
			var tile_map_position = Vector2i(column, row) + cells.position
			tile_map_preview.set_cell(0, tile_map_position, 0, tile_set_position) 


func preview_cells_line(origins: Array):
	var tile_map_preview = setup_tile_map_preview()
	
	for origin in origins:
		for column in brush.size.x:
			for row in brush.size.y:
				var tile_set_position = Vector2i(column % brush.size.x, row % brush.size.y) + brush.position
				var tile_map_position = Vector2i(column, row) + origin
				tile_map_preview.set_cell(0, tile_map_position, 0, tile_set_position) 


func preview_move_tile_set_selection(start_pos, end_pos): #used for tile map selection
	var selected_cells = get_selected_cells_as_dictionary()
	var change = get_cell(end_pos) - get_cell(start_pos)
	#tile_map_selection.position += Vector2i(change)
	#tile_map_cursor.position = tile_map_selection.position * 16
	#tile_map_cursor.size = tile_map_selection.size * 16
	
	var tile_map_preview = setup_tile_map_preview()
	
	for layer in selected_cells:
		for cell in selected_cells[layer]:
			var old_cell_pos = cell[0]
			var new_cell_pos = cell[0] + change
			var tile_pos = cell[1]
			#preview_tile_map.set_cell(layer, old_cell_pos, -1, tile_pos) #erase old
			tile_map_preview.set_cell(layer, new_cell_pos, 0, tile_pos)


func setup_tile_map_preview() -> Node:
	if w.current_level.has_node("TileMapPreview"):
		w.current_level.get_node("TileMapPreview").queue_free()
	
	var tile_map_preview = TILE_MAP_PREVIEW.instantiate()
	tile_map_preview.tile_set = w.current_level.get_node("TileMap").tile_set
	w.current_level.add_child(tile_map_preview)
	return tile_map_preview


func preview_actor_spawn(actor_path, pos):
	var preview = ACTOR_SPAWN_PREVIEW.instantiate()
	preview.actor_path = actor_path
	preview.global_position = (pos * 16) + Vector2i(8, 16)
	spawn_collection.add_child(preview)

#func preview_entity(pos, entity_path, entity_type):
	#var preview = ENTITY_PREVIEW.instantiate()
	#preview.entity_type = entity_type
	#preview.entity_path = entity_path
	#preview.global_position = pos
	#match entity_type:
		#"enemy", "npc", "player", "boss", "pickup":
			#actor_collection.add_child(preview)
		#"prop":
			#prop_collection.add_child(preview)
		#"trigger":
			#trigger_collection.add_child(preview)
		#_:
			#printerr("ERROR: cannot find entity_type: " + entity_type)


func free_previews():
	for e in get_tree().get_nodes_in_group("Previews"):
		e.queue_free()



### GETTERS ###


func get_cell(mouse_pos) -> Vector2i:
	var local_pos = tile_map.to_local(mouse_pos)
	var map_pos = tile_map.local_to_map(local_pos)
	return map_pos

func get_cells_centerbox(mouse_pos) -> Rect2i:
	var cells = Rect2i()
	var brush_size = brush.size
	var center_cell = get_cell(mouse_pos)
	#print(center_cell)
	var horz_bounds = floor((brush_size.x - 1)/2) #floor these so that the center tile is the top left given an even number for b
	var vert_bounds = floor((brush_size.y - 1)/2)
	cells = Rect2i(Vector2i(center_cell) - Vector2i(horz_bounds, vert_bounds), brush_size)
	return cells

func get_cells_box(start_pos, end_pos) -> Rect2i:
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var cells = Rect2i( \
		Vector2i(min(start.x, end.x), \
		min(start.y, end.y)),
		Vector2i.ONE)
		
	cells = cells.expand( \
	Vector2i(max(start.x+1, end.x+1), \
	max(start.y+1, end.y+1)))
	
	return cells


func get_cells_line_origins(start_pos, end_pos) -> Array:
	var origins = []
	var start = get_cell(start_pos)
	var end = get_cell(end_pos)
	var cb = get_cells_box(start_pos, end_pos)
	var sign = Vector2i(sign(end_pos.x - start_pos.x), sign(end_pos.y - start_pos.y))
	var min = cb.position
	var max = cb.position + cb.size
	var d = cb.size
	
	if d.x >= (brush.size.x/brush.size.y) * d.y:
		for column in range(min.x, max.x):
			if column % brush.size.x == 0: #is origin of a brush
				var row = round((d.y * ((column * sign.y) - (start.x * sign.y)) / (d.x * sign.x)) + start.y)
				origins.append(Vector2i(column, row))
	
	else: #tall
		for row in range(min.y, max.y):
			if row % brush.size.y == 0: #is origin of a brush
				var column = round((d.x * ((row * sign.x) - (start.y * sign.x)) / (d.y * sign.y)) + start.x)
				origins.append(Vector2i(column, row))
	
	return origins



### HELPER GETTERS ###

func get_tile_map_layer(y_pos: int) -> int:
	var tile_map_layer = 0
	match y_pos:
		0, 1, 2, 3: #FarBack
			tile_map_layer = 0
		4, 5, 6, 7: #Back
			tile_map_layer = 1
		8, 9, 10, 11: #Front
			tile_map_layer = 2
		12, 13, 14, 15: #FarFront
			tile_map_layer = 3
		_:
			printerr("ERROR: Tile position is too large in y-axis to accurately determine its tile map layer, defaulting to 0")
	return tile_map_layer



func grid_pos_has_entity(grid_pos) -> bool: #TODO: add props
	var out = false
	var selected_entities = []
	for a in get_tree().get_nodes_in_group("ActorSpawns"):
		selected_entities.append(a.get_node("CollisionShape2D"))
	for e in selected_entities:
		if get_cell(e.global_position) == grid_pos:
			out = true
			return out
	return out


### HELPERS

func set_tool(new_tool = "", new_subtool = ""):
	#Cursors
	if new_subtool == "paint":
		mc.display("brush")
		clear_tile_map_cursor()
	elif new_subtool == "select":
		mc.display("grabopen")
	elif new_subtool == "grab":
		mc.display("grabclosed")
	else:
		mc.display("arrow")
	
	
	free_previews()
	active_tool = new_tool
	if new_subtool == "":
		match active_tool: #default subtools
			"tile": new_subtool = "paint"
			"grab": new_subtool = "hold"
			"enemy": new_subtool = "place"
			_: new_subtool = ""
	
	subtool = new_subtool

func clear_tile_map_cursor():
	tile_map_selection = Rect2i(0,0,0,0)
	tile_map_cursor.size = Vector2i.ZERO
	tile_map_cursor.position = Vector2i.ZERO

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



### TILES SIGNALS

#func on_terrain_toggled(toggle): #DEBUG
#	create_tile_set_from_texture(load("res://assets/Tile/VillageTerrain.png"))

func _on_Tiles_tile_transform_updated(tile_rotation_degrees, tile_scale_vector):
	pass # Replace with function body. #TODO move to tiles code

func on_layer_changed(layer_id): #from inspector
	active_tile_map_layer = layer_id
	emit_signal("layer_updated", active_tile_map_layer)


### MISC SIGNALS

func _on_viewport_size_changed():
	await get_tree().process_frame
	$Margin.size = Vector2(get_tree().get_root().size) / Vector2(w.get_node("EditorLayer").scale)
	setup_windows()

func on_tab_selected(tab_index): #tab buttons
	$Main/Win/Tab.current_tab = tab_index

func on_tab_changed(tab):
	var tab_name = $Main/Win/Tab.get_child(tab).name
	emit_signal("tab_changed", tab_name)
	
	if $Main/Win/TabButtons/VBox.get_child_count() == 0: return #not ready to start
	for c in $Main/Win/TabButtons/VBox.get_children():
		c.size_flags_vertical = Control.SIZE_SHRINK_END
	$Main/Win/TabButtons/VBox.get_child(tab).size_flags_vertical = Control.SIZE_FILL
	clear_tile_map_cursor()
	
	match tab_name:
		"Tiles": 
			set_tool("tile")
			#set_entities_pickable(false)
			inspector.on_deselected()
		"TileSet":
			set_tool("tile_set")
		"Levels":
			set_tool("level")
			emit_signal("level_selected", w.current_level)
		"Enemies": 
			set_tool("entity", "enemy")
			#set_entities_pickable()
		"Props":
			set_tool("entity", "prop")
			#set_entities_pickable()
		"NPCs":
			set_tool("entity", "npc")
			#set_entities_pickable()
		"Triggers":
			set_tool("entity", "trigger")
			#set_entities_pickable()
		_:
			print("WARNING: could not find tab with name: " + $Main/Win/Tab.get_child(tab).name)
