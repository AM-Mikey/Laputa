extends Node2D

#const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const INVENTORY = preload("res://src/UI/Inventory/Inventory.tscn")
const LEVEL_TEXT = preload("res://src/UI/LevelText.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")
const PAUSEMENU = preload("res://src/UI/PauseMenu/PauseMenu.tscn")
#const POPUP = preload("res://src/UI/PopupText.tscn")
const JUNIPER = preload("res://src/Actor/Player/Juniper.tscn")
const TITLE = preload("res://src/UI/TitleScreen.tscn")
const TITLECAM = preload("res://src/Utility/TitleCam.tscn")

var resolution_scale = 4.0
var viewport_size_ignore = false

var save_path = "user://save.dat"
var temp_path = "user://temp.dat"
var data = {
	 "player_data" : {},
	"level_data" : {}
	}

@export var development_stage: String = "Alpha"
var internal_version: String = get_internal_version()
@export var release_version: String
@export var is_release = false
@export var do_skip_title = false
@export var debug_visible = false
@export var gamemode = "story"

@export var start_level_path: String
@onready var current_level = load(start_level_path).instantiate() #assumes current level to start with, might cause issues down the line
@onready var ui = $UILayer
@onready var el = $EditorLayer
@onready var front = $Front
@onready var middle = $Middle
@onready var back = $Back

func _ready():
	var _err = get_tree().root.connect("size_changed", Callable(self, "on_viewport_size_changed"))
	on_viewport_size_changed()
	
	if not do_skip_title: #TODO: update this
		ui.add_child(TITLE.instantiate())
		add_child(TITLECAM.instantiate())
		first_time_level_setup()
	else:
		first_time_level_setup()

	load_options()



func get_internal_version() -> String:
	var current_date = Time.get_date_dict_from_system()
	var years_since = current_date["year"] - 2021
	var months_since = current_date["month"] - 3
	var days_since = current_date["day"] - 18
	
	months_since += 12 * years_since
	
	if days_since < 0:
		
		var days_last_month
		match current_date["month"]:
			1, 2, 4, 6, 8, 9, 11: 
				days_last_month = 31
			3:
				days_last_month = 28
			5, 7, 10, 12:
				days_last_month = 30
			
		return(str(months_since -1) + "m" + str(days_last_month + days_since) + "d")
	else:
		return(str(months_since) + "m" + str(days_since) + "d")



#func set_debug_visible(vis = !debug_visible): #makes triggers and visutils visible #TODO redo this system
	#debug_visible = vis
	#for t in get_tree().get_nodes_in_group("TriggerVisuals"):
		#t.visible = vis
	#for u in get_tree().get_nodes_in_group("VisualUtilities"):
		#u.visible = vis
	#print("debug_visible == ", debug_visible)


func _input(event):
	if event.is_action_pressed("inventory") and has_node("Juniper"):
		if not ui.has_node("Inventory") and not get_tree().paused and not $Juniper.disabled and $Juniper.can_input:
			var inventory = INVENTORY.instantiate()
			ui.add_child(inventory)


	if event.is_action_pressed("pause") and not ui.has_node("TitleScreen"):
		if not ui.has_node("PauseMenu") and not get_tree().paused:
			get_tree().paused = true
			
			if ui.has_node("HUD"):
				$UILayer/HUD.visible = false
			if ui.has_node("DialogBox"):
				$UILayer/DialogBox.visible = false
			
			var pause_menu = PAUSEMENU.instantiate()
			ui.add_child(pause_menu)
	
	if event.is_action_pressed("window_maximize"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else: 
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

### LEVEL CHANGE ###

func first_time_level_setup():
	print("first time level setup")
	add_child(JUNIPER.instantiate())
	$Juniper/PlayerCamera.position_smoothing_enabled = false
	ui.add_child(HUD.instantiate())
	
	current_level = load(start_level_path).instantiate()
	add_child(current_level)
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		$Juniper.global_position = s.global_position
	
	match current_level.level_type:
		current_level.LevelType.NORMAL:
			if current_level.has_node("LevelCamera"):
				$Juniper/PlayerCamera.enabled = false
			else:
				$Juniper/PlayerCamera.enabled = true
		current_level.LevelType.PLAYERLESS_CUTSCENE:
			$Juniper.queue_free()
			$UILayer/HUD.queue_free()
	
	#wipe would go here if we want one
	display_level_text(current_level)
	read_level_data_from_temp()
	await get_tree().process_frame
	$Juniper/PlayerCamera.position_smoothing_enabled = true


func change_level_via_code(level_path):
	print("changing level via code...")
	if ui.has_node("DialogBox"): $UILayer/DialogBox.stop_printing()
	clear_spawn_layers()
	current_level.queue_free()
	await get_tree().process_frame

	add_child(JUNIPER.instantiate())
	$Juniper/PlayerCamera.position_smoothing_enabled = false
	ui.add_child(HUD.instantiate())
	
	current_level = load(level_path).instantiate()
	add_child(current_level)
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		$Juniper.global_position = s.global_position
	
	match current_level.level_type:
		current_level.LevelType.NORMAL:
			if current_level.has_node("LevelCamera"):
				$Juniper/PlayerCamera.enabled = false
			else:
				$Juniper/PlayerCamera.enabled = true
		current_level.LevelType.PLAYERLESS_CUTSCENE:
			$Juniper.queue_free()
			$UILayer/HUD.queue_free()
	
	#wipe would go here if we want one
	display_level_text(current_level)
	read_level_data_from_temp()
	await get_tree().process_frame
	$Juniper/PlayerCamera.position_smoothing_enabled = true


func change_level_via_trigger(level_path, door_index):
	print("changing level via trigger...")
	write_level_data_to_temp()
	if ui.has_node("DialogBox"): $UILayer/DialogBox.stop_printing()
	clear_spawn_layers()
	var old_level_path = current_level.scene_file_path
	current_level.queue_free()
	await get_tree().process_frame
	
	current_level = load(level_path).instantiate()
	add_child(current_level)
	
	if current_level.level_type == current_level.LevelType.NORMAL:
		$Juniper/PlayerCamera.position_smoothing_enabled = false
		$Juniper/PlayerCamera.enabled = not current_level.has_node("LevelCamera") #turn off camera if level has one already
	
	#### get the door with the right index
	var doors_found = 0
	await get_tree().process_frame #give time for triggers to load
	var triggers = get_tree().get_nodes_in_group("LevelTriggers")
	for t in triggers:
		var old_level_name = old_level_path.trim_prefix("res://src/Level/").trim_suffix(".tscn")
		if t.level == old_level_name and t.door_index == door_index:
			doors_found += 1
			var size = t.get_node("CollisionShape2D").shape.size
			if t.is_in_group("LoadZones"):
				match t.direction:
					t.Direction.LEFT: $Juniper.global_position = t.global_position + Vector2(32, size.y)
					t.Direction.RIGHT: $Juniper.global_position = t.global_position + Vector2(-32, size.y)
					t.Direction.UP: $Juniper.global_position = t.global_position + Vector2((size.x * 0.5), -32)
					t.Direction.DOWN: $Juniper.global_position = t.global_position + Vector2((size.x * 0.5), 32)
					_: printerr("ERROR: Invalid direction on Load Zone")
			elif t.is_in_group("Doors"):
				$Juniper.global_position = t.global_position + Vector2(size.x * 0.5, size.y)
		
		if doors_found == 0:
			printerr("ERROR: could not find door with right index")
		if doors_found > 1:
			printerr("ERROR: more than one door with same index")
	
	###transition out
	if ui.has_node("TransitionWipe"): #LOADZONES
		await get_tree().create_timer(0.8).timeout
		$UILayer/TransitionWipe.play_out_animation()
		await get_tree().create_timer(0.2).timeout #wait for a bit of the animation to finish
		$Juniper.can_input = true

	elif ui.has_node("TransitionIris"): #DOORS
		await get_tree().create_timer(0.4).timeout
		$UILayer/TransitionIris.play_out_animation()
		await get_tree().create_timer(0.2).timeout #wait for a bit of the animation to finish
		$Juniper.can_input = true

	display_level_text(current_level)
	#await get_tree().create_timer(0.01).timeout
	$Juniper/PlayerCamera.position_smoothing_enabled = true
	
	if current_level.level_type == current_level.LevelType.PLAYERLESS_CUTSCENE:
		#TODO: right now juniper isn't unloaded between levels
		$Juniper.queue_free()
		$UILayer/HUD.queue_free()
	
	read_level_data_from_temp()

func display_level_text(level):
	if ui.has_node("LevelText"):
		$UILayer/LevelText.free()
	var level_text = LEVEL_TEXT.instantiate()
	level_text.text = level.name #TODO: in final version switch this to display name
	ui.add_child(level_text)

### SAVE/LOAD ###

func write_player_data_to_save():
	var pc = $Juniper
	var guns = pc.guns
	var gun_data = {}
	
	for g in guns.get_children():
		gun_data[g.name] = {
			"level" : g.level,
			"xp" : g.xp
			}
		if g.max_ammo != 0:
			gun_data[g.name]["ammo"] = g.ammo
	
	data["player_data"] = {
		"current_level" : current_level.scene_file_path,
		"position" : pc.position,
		"hp" : pc.hp,
		"max_hp" : pc.max_hp,
		"money" : pc.money,
		"inventory" : pc.inventory,
		"gun_data" : gun_data
	}
	
	write_to_file(save_path, data)
	print("player data written to save")


func read_player_data_from_save():
	var pc = $Juniper
	var guns = pc.guns
	
	var scoped_data = read_from_file(save_path)
	var player_data = scoped_data["player_data"]
	
	change_level_via_code(player_data["current_level"])
	await get_tree().process_frame
	
	pc.position = player_data["position"]
	pc.hp = player_data["hp"]
	pc.max_hp = player_data["max_hp"]
	pc.money = player_data["money"]
	pc.inventory = player_data["inventory"]
	
	
	for g in guns.get_children():
		g.free()
		
	for d in player_data["gun_data"]:
		var gun_scene = load("res://src/Gun/%s" %d + ".tscn")
		if gun_scene == null:
			printerr("ERROR: cannot find gun scene at: res://src/Gun/%s" %d + ".tscn")
			return
		guns.add_child(gun_scene.instantiate())

	for g in guns.get_children():
		g.level = player_data["gun_data"][g.name]["level"]
		g.xp = player_data["gun_data"][g.name]["xp"]
		if g.max_ammo != 0:
			g.ammo = player_data["gun_data"][g.name]["ammo"]
	
	pc.emit_signal("hp_updated", pc.hp, pc.max_hp)
	pc.emit_signal("guns_updated", guns.get_children())
	pc.update_inventory()
			
	print("player data loaded")

func write_level_data_to_temp():
	var limited_props = []
	for p in get_tree().get_nodes_in_group("LimitedProps"):
		var scoped_data = {
			"position" : p.position,
			"spent" : p.spent
			}
		limited_props.append(scoped_data)
	
	var limited_triggers = []
	for t in get_tree().get_nodes_in_group("LimitedTriggers"):
		var scoped_data = {
			"position" : t.position,
			"spent" : t.spent
			}
		limited_triggers.append(scoped_data)
	
	data["level_data"][current_level.name] = {
		"limited_props": limited_props,
		"limited_triggers": limited_triggers
	}
	
	write_to_file(temp_path, data)
	print("level data saved to temp")


### COPY ###

func copy_level_data_from_save_to_temp():
	var save_data = read_from_file(save_path)

	if save_data.has("level_data"):
		var scoped_data = {}
		scoped_data["level_data"] = save_data["level_data"]
		write_to_file(temp_path, scoped_data)
	else:
		print("no level data to copy from save to temp")
		return

	print("level data copied from save to temp")


func copy_level_data_from_temp_to_save():
	var temp_data = read_from_file(temp_path)
	var save_data = read_from_file(save_path)
	
	if temp_data.has("level_data"):
		var scoped_data = {}
		scoped_data["player_data"] = save_data["player_data"]
		scoped_data["level_data"] = temp_data["level_data"]
		
		write_to_file(save_path, scoped_data)
	else:
		print("no level data to copy from temp to save")
		return
	
	print("level data copied from temp to save")


### LOAD ###

func read_level_data_from_temp():
	var scoped_data = read_from_file(temp_path)
	if scoped_data == null:
		return
	if scoped_data["level_data"].has(current_level.name): #if it finds level data for this level
		var current_level_data = scoped_data["level_data"][current_level.name]

		for saved in current_level_data["limited_props"]:
			for current in get_tree().get_nodes_in_group("LimitedProps"):
				if saved["position"] == current.position:
					if saved["spent"]:
						current.expend_prop()
		
		for saved in current_level_data["limited_triggers"]:
			for current in get_tree().get_nodes_in_group("LimitedTriggers"):
				if saved["position"] == current.position:
					if saved["spent"]:
						current.expend_trigger()

	else:
		print("no previous level data in temp")
		return
	print("level data loaded from temp")



func read_level_data_from_save():
	var scoped_data = read_from_file(save_path)
	if scoped_data["level_data"].has(current_level.name): #if it finds level data for this level
		var current_level_data = scoped_data["level_data"][current_level.name]
		
		for saved in current_level_data["limited_props"]:
			for current in get_tree().get_nodes_in_group("LimitedProps"):
				if saved["position"] == current.position:
					if saved["spent"]:
						current.expend_prop()

	else:
		print("no previous level data in save")
		return
	print("level data loaded from save")



##################################################################################
func read_from_file(file_path):
	var read_data
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		read_data = file.get_var()
	else:
		printerr("ERROR: cannot read file at: " + file_path)
	return read_data

func write_to_file(file_path, written_data):
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file: #if this doesnt work try file.get_error() == OK
		file.store_var(written_data)
		file.close()
	else:
		printerr("ERROR: cannot write data to " + file_path)
##################################################################################

func load_options():
	var options = OPTIONS.instantiate()
	options.ishidden = true
	ui.add_child(options)
	options.tabs.get_node("Settings").load_settings()
	options.tabs.get_node("KeyConfig").load_input_map()
	
	await get_tree().process_frame
	options.queue_free()

func clear_spawn_layers():
	for c in back.get_children():
		c.free()
	for c in middle.get_children():
		c.free()
	for c in front.get_children():
		c.free()



func on_viewport_size_changed():
	if viewport_size_ignore:
		return
	print("viewport size changed")
	var viewport_size = get_tree().get_root().size
	
	var tiles_visible_y = 15.0
	var urs = viewport_size.y / (16.0 * tiles_visible_y)
	if urs - floor(urs) == 0.5:
		resolution_scale = floori(urs) #round 0.5 down
	else:
		resolution_scale = roundi(urs) #else round normally
	if resolution_scale == 0: 
		resolution_scale = 0.0001 #div by 0 protection


	ui.scale = Vector2(resolution_scale, resolution_scale)
	back.scale = Vector2(resolution_scale, resolution_scale)
	var half_scale = max(ceil(resolution_scale/2.0), 1)
	el.scale = Vector2(half_scale, half_scale)
	$DebugLayer.scale = Vector2(half_scale, half_scale)
