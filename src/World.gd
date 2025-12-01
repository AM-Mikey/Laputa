extends Node2D

#const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const INVENTORY = preload("res://src/UI/Inventory/Inventory.tscn")
const LEVEL_TEXT = preload("res://src/UI/LevelText.tscn")

const PAUSEMENU = preload("res://src/UI/PauseMenu/PauseMenu.tscn")
#const POPUP = preload("res://src/UI/PopupText.tscn")
const JUNIPER = preload("res://src/Player/Juniper.tscn")
const TITLE = preload("res://src/UI/TitleScreen.tscn")
const TITLECAM = preload("res://src/Utility/TitleCam.tscn")

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
@onready var uig = $UILayer/UIGroup
@onready var el = $EditorLayer
@onready var dl = $DebugLayer
@onready var bl = $BlackoutLayer
@onready var ml = $MenuLayer
@onready var front = $Front
@onready var middle = $Middle
@onready var back = $Back

func _ready():
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
		if not uig.has_node("Inventory") and not get_tree().paused and not $Juniper.disabled and $Juniper.can_input:
			var inventory = INVENTORY.instantiate()
			uig.add_child(inventory)


	if event.is_action_pressed("pause") and not ml.has_node("TitleScreen"):
		if not ml.has_node("PauseMenu") and not get_tree().paused:
			get_tree().paused = true
			ui.visible = false
			var pause_menu = PAUSEMENU.instantiate()
			ml.add_child(pause_menu)

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
	uig.add_child(HUD.instantiate())

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
			$UILayer/UIGroup/HUD.queue_free()

	#wipe would go here if we want one
	display_level_text(current_level)
	SaveSystem.read_level_data_from_temp(current_level)

	await(get_tree().process_frame)
	$Juniper/PlayerCamera.position_smoothing_enabled = true


func change_level_via_code(level_path):
	print("changing level via code...")
	if uig.has_node("DialogBox"): $UILayer/UIGroup/DialogBox.exit()
	clear_spawn_layers()
	current_level.queue_free()
	current_level = null

	if (get_node_or_null("Juniper")):
		$Juniper.free()
	add_child(JUNIPER.instantiate())

	if uig.has_node("DialogBox"):
		$UILayer/UIGroup/DialogBox.exit()

	if ml.has_node("PauseMenu"):
		ml.get_node("PauseMenu").unpause()

	if (uig.get_node_or_null("HUD")):
		uig.get_node("HUD").free()
	uig.add_child(HUD.instantiate())

	$Juniper/PlayerCamera.position_smoothing_enabled = false

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
			$UILayer/UIGroup/HUD.queue_free()

	#wipe would go here if we want one
	display_level_text(current_level)
	SaveSystem.read_level_data_from_temp(current_level)

	await(get_tree().process_frame)
	$Juniper/PlayerCamera.position_smoothing_enabled = true


func change_level_via_trigger(level_path, door_index):
	print("changing level via trigger...")
	SaveSystem.write_level_data_to_temp(current_level)
	if uig.has_node("DialogBox"): $UILayer/UIGroup/DialogBox.exit()
	clear_spawn_layers()
	var old_level_path = current_level.scene_file_path
	current_level.queue_free()
	current_level = null

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

		var do_door_check = false
		if t.is_in_group("Doors"):
			if t.same_level and t.door_index == door_index:
				do_door_check = true
		if t.level == old_level_name and t.door_index == door_index:
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

		#print("doors: ", doors_found)
		if doors_found == 0:
			printerr("ERROR: could not find door with right index")
		if doors_found > 1:
			printerr("ERROR: more than one door with same index")

	###transition out
	if bl.has_node("TransitionWipe"): #LOADZONES
		await get_tree().create_timer(0.8).timeout
		$BlackoutLayer/TransitionWipe.play_out_animation()
		await get_tree().create_timer(0.2).timeout #wait for a bit of the animation to finish
		$Juniper.can_input = true

	elif bl.has_node("TransitionIris"): #DOORS
		await get_tree().create_timer(0.4).timeout
		$BlackoutLayer/TransitionIris.play_out_animation()
		await get_tree().create_timer(0.2).timeout #wait for a bit of the animation to finish
		$Juniper.can_input = true

	display_level_text(current_level)
	#await get_tree().create_timer(0.01).timeout
	$Juniper/PlayerCamera.position_smoothing_enabled = true

	if current_level.level_type == current_level.LevelType.PLAYERLESS_CUTSCENE:
		#TODO: right now juniper isn't unloaded between levels
		$Juniper.queue_free()
		$UILayer/UIGroup/HUD.queue_free()

	SaveSystem.read_level_data_from_temp(current_level)

func display_level_text(level):
	if uig.has_node("LevelText"):
		$UILayer/UIGroup/LevelText.free()
	var level_text = LEVEL_TEXT.instantiate()
	level_text.text = level.name #TODO: in final version switch this to display name
	uig.add_child(level_text)



func clear_spawn_layers():
	for c in back.get_children():
		c.free()
	for c in middle.get_children():
		c.free()
	for c in front.get_children():
		c.free()

### SIGNALS ###

func _resolution_scale_changed(resolution_scale):
	ui.scale = Vector2(resolution_scale, resolution_scale)
	back.scale = Vector2(resolution_scale, resolution_scale)
	bl.scale = Vector2(resolution_scale, resolution_scale)
	var half_scale = max(ceil(resolution_scale/2.0), 1)
	el.scale = Vector2(half_scale, half_scale)
	dl.scale = Vector2(half_scale, half_scale)
	ml.scale = Vector2(vs.menu_resolution_scale, vs.menu_resolution_scale)
