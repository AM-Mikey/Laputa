extends Node2D

const HUD = preload("res://src/UI/HUD/HUD.tscn")
const INVENTORY = preload("res://src/UI/Inventory/Inventory.tscn")
const LEVEL_TEXT = preload("res://src/UI/LevelText.tscn")

const PAUSEMENU = preload("res://src/UI/PauseMenu.tscn")
const JUNIPER = preload("res://src/Player/Juniper.tscn")
const TITLE = preload("res://src/UI/TitleScreen.tscn")
const TITLECAM = preload("res://src/Utility/TitleCam.tscn")

var current_level

@export var development_stage: String = "Alpha"
var internal_version: String = get_internal_version()
@export var release_version: String
@export var is_release = false
@export var do_skip_title = false
@export var debug_visible = false

@export var start_level_path: String
@onready var ui = $UILayer
@onready var hl = $HUDLayer
@onready var el = $EditorLayer
@onready var dl = $DebugLayer
@onready var bl = $BlackoutLayer
@onready var ml = $MenuLayer
@onready var il = $InventoryLayer
@onready var dll = $DialogLayer
@onready var front = $Front
@onready var middle = $Middle
@onready var back = $Back



func _ready():
	self.visibility_layer = 2
	self.child_entered_tree.connect(child_layer_set)
	for node: Node in [front, middle, back]:
		if node is CanvasItem:
			node.visibility_layer = 2
		node.child_entered_tree.connect(child_layer_set)

	if not do_skip_title: #TODO: update this
		ml.add_child(TITLE.instantiate())
		add_child(TITLECAM.instantiate())
		first_time_level_setup()
	else:
		first_time_level_setup()

	SaveSystem.load_options()

	# Grab the default viewport width and height
	var width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height = ProjectSettings.get_setting("display/window/size/viewport_height")

	# Apply them to the root window as the minimum size
	var main_window = get_tree().get_root()
	main_window.set_min_size(Vector2i(width, height))

	vs.connect("scale_changed", Callable(self, "_resolution_scale_changed"))
	_resolution_scale_changed(vs.resolution_scale)


func child_layer_set(c: Node): #set the visibility layer of all children to layer 2 so that they're rendered by the subviewport
	if c == self:
		return
	c.child_entered_tree.connect(child_layer_set) #why this line?
	if c is CanvasItem:
		c.visibility_layer = 2


#func set_debug_visible(vis = !debug_visible): #makes triggers and visutils visible #TODO redo this system
	#debug_visible = vis
	#for t in get_tree().get_nodes_in_group("TriggerVisuals"):
		#t.visible = vis
	#for u in get_tree().get_nodes_in_group("VisualUtilities"):
		#u.visible = vis
	#print("debug_visible == ", debug_visible)


func _input(event):
	if event.is_action_pressed("inventory") && f.pc():
		if !il.has_node("Inventory") && !get_tree().paused && !f.pc().disabled && inp.can_act && !dll.has_node("DialogBox"):
			il.add_child(INVENTORY.instantiate())

	if event.is_action_pressed("pause") && !ml.has_node("TitleScreen") && !el.has_node("Editor"):
		if not ml.has_node("PauseMenu") and not get_tree().paused:
			ml.add_child(PAUSEMENU.instantiate())

	if event.is_action_pressed("window_maximize"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


### LEVEL CHANGE ###

func first_time_level_setup():
	bl.visible = true #TODO: this is a bandaid solution to saving in editor causing world.gd to have some layers invisible. since it's only supposed to save the current level, I'm not sure why this is affecting the world node
	ui.visible = true
	print("first time level setup")
	add_child(JUNIPER.instantiate())
	get_node("HUDLayer/HUDGroup").add_child(HUD.instantiate())
	current_level = load(start_level_path).instantiate()
	add_child(current_level)
	for wg in get_tree().get_nodes_in_group("WaypointGlobals"):
		if wg.uses_spawn:
			wg.queue_free()

	$Juniper.global_position = get_spawn_point().global_position
	$Juniper/PlayerCamera.reset()

	#wipe would go here if we want one
	display_level_text(current_level)
	run_conversation_on_enter(current_level)
	await get_tree().physics_frame
	await get_tree().physics_frame #wait for npcs to spawn, takes 2 frames for some reason
	setup_missions(false, "first_time")

func change_level_via_code(level_path, use_save_data):
	print("changing level via code")
	inp.can_act = true
	if ml.has_node("TitleScreen"): ml.get_node("TitleScreen").exit()
	if ml.has_node("PauseMenu"): ml.get_node("PauseMenu").exit()
	if has_node("MenuLayer/LevelSelect"): get_node("MenuLayer/LevelSelect").queue_free()
	if f.db(): await f.db().exit()
	if f.hud():
		$HUDLayer/HUDAnimator.play("RESET")
		f.hud().free()
	clear_spawn_layers()
	current_level.free()
	current_level = null
	if f.pc() != null: $Juniper.free()

	add_child(JUNIPER.instantiate())
	$Juniper.velocity = Vector2.ZERO
	get_node("HUDLayer/HUDGroup").add_child(HUD.instantiate())
	current_level = load(level_path).instantiate()
	add_child(current_level)
	for wg in get_tree().get_nodes_in_group("WaypointGlobals"):
		if wg.uses_spawn:
			wg.queue_free()

	$Juniper.global_position = get_spawn_point().global_position
	$Juniper/PlayerCamera.reset()

	#wipe would go here if we want one
	display_level_text(current_level)
	run_conversation_on_enter(current_level)
	if use_save_data:
		SaveSystem.read_level_data_from_temp(current_level)
	await get_tree().physics_frame
	await get_tree().physics_frame #wait for npcs to spawn, takes 2 frames for some reason
	if use_save_data:
		SaveSystem.read_dialog_data_from_temp(current_level)
	setup_missions(use_save_data, "code")



func change_level_via_trigger(level_path, door_index):
	print("changing level via trigger")
	inp.can_act = true
	SaveSystem.write_level_data_to_temp(current_level)
	if f.db(): await f.db().exit()
	if f.hud(): $HUDLayer/HUDAnimator.play("RESET")
	clear_spawn_layers()
	var old_level_path = current_level.scene_file_path
	current_level.free()
	current_level = null
	#Note: Juniper and HUD are never freed this way

	current_level = load(level_path).instantiate()
	add_child(current_level)
	for wg in get_tree().get_nodes_in_group("WaypointGlobals"):
		if wg.uses_spawn:
			wg.queue_free()

	$Juniper/PlayerCamera.reset()

	do_transition(old_level_path, level_path)

	SaveSystem.read_level_data_from_temp(current_level)
	await get_tree().process_frame
	await get_tree().process_frame #wait for npcs to spawn, takes 2 frames for some reason
	SaveSystem.read_dialog_data_from_temp(current_level)
	setup_missions(false, "trigger")
	setup_door(door_index, old_level_path)



func do_transition(old_level_path, level_path):
	inp.can_act = false
	if bl.has_node("TransitionWipe"): #LOADZONES
		await get_tree().create_timer(0.8).timeout
		$BlackoutLayer/TransitionWipe.play_out_animation()
		await $BlackoutLayer/TransitionWipe.tree_exiting #wait for a bit of the animation to finish
		inp.can_act = true
		if old_level_path != level_path:
			display_level_text(current_level)
		run_conversation_on_enter(current_level)

	elif bl.has_node("TransitionIris"): #DOORS
		await get_tree().create_timer(0.4).timeout
		$BlackoutLayer/TransitionIris.play_out_animation()
		await $BlackoutLayer/TransitionIris.tree_exiting #wait for a bit of the animation to finish
		inp.can_act = true
		if old_level_path != level_path:
			display_level_text(current_level)
		run_conversation_on_enter(current_level)


func setup_missions(use_save_data: bool, type = "first_time"):
	if !current_level.mission_level_update: return
	print("setting up missions")
	#main mission
	if use_save_data: #setup all main and side stages
		ms.setup_level_from_mission_progress_history()
	else:
		var update_conversations = true if type in ["first_time", "code"] else false

		if type != "trigger": #Don't if we're moving thru a door or loadzone
			if current_level.debug_main_mission_stage_name: #add all stages until we get to the one that matches.
				var main_array = []
				var main_array_completed = false
				for s in ms.MAIN_MISSION:
					if !main_array_completed:
						main_array.append(["Main", s[0]])
						if s[0] == current_level.debug_main_mission_stage_name:
							ms.main_mission_stage = s
							main_array_completed = true
				ms.setup_level_from_array(main_array, update_conversations)
			else: #start with the very first main mission stage
				ms.main_mission_stage = ms.MAIN_MISSION[0]
				ms.update_level_via_mission("Main", "current", update_conversations)

		#side missions
		for m in current_level.side_missions_on_enter: #never need to add these if we're loading save data
			ms.start_side_mission(m) #Note: this does runtime updates for these missions

		var side_array = []
		var side_array_completed = false
		for m in ms.side_missions:
			if !side_array_completed:
				for s in m.stages:
					if !side_array_completed:
						side_array.append([m.resource_path.get_file().trim_suffix(".tres"), s[0]])
						if s[0] == m.current_stage:
							side_array_completed = true
		ms.setup_level_from_array(side_array, update_conversations)
		ms.mission_progress_check()



func setup_door(door_index, old_level_path):
	var doors_found = 0

	for t in get_tree().get_nodes_in_group("LevelTriggers"):
		var do_door_check = false
		if t.is_in_group("Doors"):
			if t.same_level && t.door_index == door_index:
				do_door_check = true
		if t.level == old_level_path && t.door_index == door_index:
			do_door_check = true

		if do_door_check:
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



### HELPERS ###

func display_level_text(level):
	if ui.has_node("LevelText"):
		$UILayer/LevelText.free()
	var level_text = LEVEL_TEXT.instantiate()
	level_text.text = level.name #TODO: in final version switch this to display name
	ui.add_child(level_text)

func run_conversation_on_enter(level):
	if level.conversation_on_enter:
		if level.level_type == level.LevelType.PLAYERLESS_CUTSCENE:
			level.do_conversation_on_enter(true)
		else:
			level.do_conversation_on_enter(false)

func clear_spawn_layers():
	for c in back.get_children():
		c.free()
	for c in middle.get_children():
		c.free()
	for c in front.get_children():
		c.free()



### GETTERS ###

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


func get_spawn_point() -> Node:
	var out
	var spawn_point_count = 0
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		out = s
		spawn_point_count += 1
	if spawn_point_count == 0:
		printerr("ERROR: LEVEL HAS NO SPAWN POINT FOR PC")
		return null
	elif spawn_point_count > 1:
		printerr("ERROR: LEVEL HAS MORE THAN ONE SPAWN POINT FOR PC")
		return null
	return out



### SIGNALS ###

func _resolution_scale_changed(resolution_scale):
	ui.scale = Vector2(resolution_scale, resolution_scale)
	hl.scale = Vector2(resolution_scale, resolution_scale)
	bl.scale = Vector2(resolution_scale, resolution_scale)
	var half_scale = max(ceil(resolution_scale / 2.0), 1)
	el.scale = Vector2(half_scale, half_scale)
	dl.scale = Vector2(half_scale, half_scale)
	ml.scale = Vector2(vs.menu_resolution_scale, vs.menu_resolution_scale)
	il.scale = Vector2(vs.inventory_resolution_scale, vs.inventory_resolution_scale)
	dll.scale = Vector2(vs.dialog_resolution_scale, vs.dialog_resolution_scale)
