extends Node2D

const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const INVENTORY = preload("res://src/UI/Inventory/Inventory.tscn")
const LEVEL_TEXT = preload("res://src/UI/LevelText.tscn")
const OPTIONS = preload("res://src/UI/Options/Options.tscn")
const PAUSEMENU = preload("res://src/UI/PauseMenu.tscn")
const POPUP = preload("res://src/UI/PopupText.tscn")
const RECRUIT = preload("res://src/Actor/Player/Recruit.tscn")
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

export var development_stage: String = "Alpha"
var internal_version: String = get_internal_version()
export var release_version: String
export var is_release = false
export var should_skip_title = false
export var visible_triggers = false

var in_menu = false

export var starting_level = "res://src/Level/Village/Village.tscn"
onready var current_level = load(starting_level).instance() #assumes current level to start with, might cause issues down the line

func _ready():
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed") #TODO err?
	on_viewport_size_changed()
	add_child(current_level)
	add_child(TITLECAM.instance())
	
	if not should_skip_title:
		load_title()
	else:
		skip_title()
	load_options()

	


func get_internal_version() -> String:
	var current_date = OS.get_date()
	var _years_since = current_date["year"] - 2021
	var months_since = current_date["month"] - 3
	var days_since = current_date["day"] - 18
	
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



	

func load_title():
	var title = TITLE.instance()
	$UILayer.add_child(title)

func skip_title():
	on_level_change(starting_level, 0, "res://assets/Music/XXXX.ogg")
	add_child(RECRUIT.instance())
	get_node("UILayer").add_child(HUD.instance())

	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		$Recruit.position = s.global_position
		print("moved player")


func _input(event):
	if Input.is_action_just_pressed("debug_print"):
		debug_print()
	
	if event.is_action_pressed("debug_reload"):
		reload_level()
	
	if event.is_action_pressed("debug_triggers"):
		visible_triggers = !visible_triggers
		for v in get_tree().get_nodes_in_group("TriggerVisuals"):
			v.visible = visible_triggers
	
	if event.is_action_pressed("debug_save"):
		var popup = POPUP.instance()
		popup.text = "quicksaved..."
		$UILayer.add_child(popup)
		write_level_data_to_temp()
		write_player_data_to_save()
		copy_level_data_from_temp_to_save()
	
	if event.is_action_pressed("debug_load"):
		var popup = POPUP.instance()
		popup.text = "loaded save"
		$UILayer.add_child(popup)
		read_player_data_from_save()
		read_level_data_from_save()
		copy_level_data_from_save_to_temp()
	
	if event.is_action_pressed("inventory") and not $Recruit.disabled:
		if not $UILayer.has_node("Inventory") and not get_tree().paused: 
			get_tree().paused = true
			$UILayer/HUD.visible = false
			var inventory = INVENTORY.instance()
			$UILayer.add_child(inventory)
	
	if event.is_action_pressed("pause") and not $UILayer.has_node("TitleScreen"):
		if not $UILayer.has_node("PauseMenu") and not get_tree().paused:
			get_tree().paused = true
			
			$UILayer/HUD.visible = false
			if self.has_node("UILayer/DialogBox"):
				self.get_node("UILayer/DialogBox").visible = false
			
			var pause_menu = PAUSEMENU.instance()
			$UILayer.add_child(pause_menu)
			



func on_level_change(level, door_index, music):
	print("level change")
	write_level_data_to_temp()
	
	### Clean up stuff we don't need
	if $UILayer.has_node("DialogBox"):
		$UILayer/DialogBox.stop_printing()
	clear_spawn_layers()
	clear_bg_layer()
	###
	
	var level_path = current_level.filename
	current_level.queue_free()
	
	yield(get_tree(), 'idle_frame') #this gives time for recruit to spawn. probably not neccesary
	var next_level = load(level).instance()
	add_child(next_level)
	
	if next_level.level_type == next_level.LevelType.NORMAL:#############################################################
		if has_node("Recruit"):
			$Recruit/PlayerCamera.smoothing_enabled = false
			$Recruit/PlayerCamera.current = not next_level.has_node("LevelCamera") #turn off camera if level has one already
			

		
		######################## get the door with the right index
		
		var doors_found = 0
		
		var triggers = get_tree().get_nodes_in_group("LevelTriggers")
		for t in triggers:
			if t.level == level_path:
				if t.is_in_group("LoadZones"):
					$Recruit.position = t.position + (t.direction * -32)
					print("found a connected zone")
					doors_found += 1
				else:
					$Recruit.position = t.position
					print("found a connected door")
					doors_found += 1
			
		if doors_found == 0:
			printerr("ERROR: could not find door with right level connection")
		
		if doors_found > 1: #more than one door with correct level connections
			doors_found = 0
			for t in triggers:
				if t.level == level_path and t.door_index == door_index:
					if t.is_in_group("LoadZones"):
						$Recruit.position = t.position + (t.direction * -32)
						print("got correct zone")
						doors_found += 1
					else:
						$Recruit.position = t.position
						print("got correct door")
						doors_found += 1
			
			if doors_found == 0:
				printerr("ERROR: could not find door with right index")
			if doors_found > 1:
				printerr("ERROR: more than one door with same index")
		
		###transition out
		var already_enabled = false
	
		#LOADZONES
		if $UILayer.has_node("TransitionWipe"):
			yield(get_tree().create_timer(0.8), "timeout")
			$UILayer/TransitionWipe.play_out_animation()
			already_enabled = true
			$Recruit.enable()

		#DOORS
		elif $UILayer.has_node("TransitionIris"):
			yield(get_tree().create_timer(0.4), "timeout")
			$UILayer/TransitionIris.play_out_animation()
			already_enabled = true
			$Recruit.enable()

		######
		if not already_enabled:
			$Recruit.enable()
			
		if $UILayer.has_node("LevelText"):
			$UILayer/LevelText.free()
		var level_text = LEVEL_TEXT.instance()
		level_text.text = next_level.name #TODO: in final version switch this to display name
		$UILayer.add_child(level_text)
		

		#enable smoothing after a bit
		yield(get_tree().create_timer(0.01), "timeout")
		$Recruit/PlayerCamera.smoothing_enabled = true
		
		

	
	if next_level.level_type == next_level.LevelType.PLAYERLESS_CUTSCENE:#############################################
		#TODO: right now recruit isn't unloaded between levels unless we're using level buttons or starting
		$Recruit.queue_free()
		$UILayer/HUD.queue_free()
		
	
	
	
	
	##################################################################################################################
	if next_level.music != music:
		load_music(next_level.music)
	
	
	current_level = next_level
	read_level_data_from_temp()
	
	
func load_music(music):
	if music:
		$MusicPlayer.stream = load(music)
		$MusicPlayer.play()
	
func write_player_data_to_save():
	var pc = $Recruit
	var weapon_data = {}
	
	for w in pc.weapon_array:
		weapon_data[w.resource_name] = {
			"level" : w.level,
			"xp" : w.xp
			}
		if w.needs_ammo:
			weapon_data[w.resource_name]["ammo"] = w.ammo
	
	data["player_data"] = {
		"current_level" : current_level.filename,
		"position" : pc.position,
		"hp" : pc.hp,
		"max_hp" : pc.max_hp,
		"total_xp" : pc.total_xp,
		"inventory" : pc.inventory,
		#"weapon_array" : pc.weapon_array,
		"weapon_data" : weapon_data
	}
	
	write_to_file(save_path, data)
	print("player data written to save")


func read_player_data_from_save():
	var pc = $Recruit
	var file = File.new()
	if file.file_exists(save_path):
		var file_read = file.open(save_path, File.READ)
		if file_read == OK:
			var scoped_data = file.get_var()
			file.close()
			
			#print(scoped_data["player_data"])
			
			on_level_change(scoped_data["player_data"]["current_level"], null, null)
			yield(get_tree(), "idle_frame")
			
			pc.position = scoped_data["player_data"]["position"]
			pc.hp = scoped_data["player_data"]["hp"]
			pc.max_hp = scoped_data["player_data"]["max_hp"]
			pc.total_xp = scoped_data["player_data"]["total_xp"]
			pc.inventory = scoped_data["player_data"]["inventory"]
			#player.setup_weapons() not sure what this did
			
			
			pc.weapon_array.clear()
			for w in scoped_data["player_data"]["weapon_data"]:
				var weapon_resource = load("res://src/Weapon/%s" %w + ".tres")
				if weapon_resource != null:
					pc.weapon_array.append(weapon_resource)
				else:
					printerr("ERROR: cannot find weapon resource at: res://src/Weapon/%s" %w + ".tres")
			for w in pc.weapon_array:
				w.level = scoped_data["player_data"]["weapon_data"][w.resource_name]["level"]
				w.xp = scoped_data["player_data"]["weapon_data"][w.resource_name]["xp"]
				if w.needs_ammo:
					w.ammo = scoped_data["player_data"]["weapon_data"][w.resource_name]["ammo"]
			
			#player.weapon_array[0].update_weapon()
			pc.get_node("WeaponManager").update_weapon() #TODO: check compatability
			pc.emit_signal("hp_updated", pc.hp, pc.max_hp)
			pc.emit_signal("weapon_updated", pc.weapon_array.front())
			pc.update_inventory()
			
			print("player data loaded")
		else:
			printerr("ERROR: player data could not be loaded!")
	else:
			printerr("ERROR: no save file found")

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
	var temp_data = read_from_file(temp_path)
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
	var file = File.new()
	var read_data
	if file.file_exists(file_path):
		var read_file = file.open(file_path, File.READ)
		if read_file == OK:
			read_data = file.get_var()
			file.close()
		else:
			printerr("ERROR: cannot read file at: " + file_path)
	else: printerr("ERROR: no file at: " + file_path)
	return read_data

func write_to_file(file_path, written_data):
	var file = File.new()
	var written_file = file.open(file_path, File.WRITE)
	if written_file == OK:
		file.store_var(written_data)
		file.close()
	else:
		printerr("ERROR: cannot write data to " + file_path)
##################################################################################

func load_options():
	var options = OPTIONS.instance()
	options.hidden = true
	$UILayer.add_child(options)
	options.get_node("TabContainer/Settings").load_settings()
	options.get_node("TabContainer/KeyConfig").load_input_map()
	
	yield(get_tree(), "idle_frame")
	options.queue_free()

func clear_spawn_layers():
	for c in $Back.get_children():
		c.free()
	for c in $Middle.get_children():
		c.free()
	for c in $Front.get_children():
		c.free()

func clear_bg_layer():
	for c in $BackgroundLayer.get_children():
		c.free()

func debug_print():
	if not $UILayer.has_node("DebugInfo"):
		var debug_info = DEBUG_INFO.instance()
		$UILayer.add_child(debug_info)
	else:
		$UILayer/DebugInfo.queue_free()

func reload_level():
	$Recruit.free() #we free and respawn them so we have a clean slate when we load in
	$UILayer/HUD.free()
	
	on_level_change(current_level.filename, 0, current_level.music)
	
#	if has_node("UILayer/TitleScreen"):
#		$UILayer/TitleScreen.queue_free()
	if has_node("UILayer/PauseMenu"):
		$UILayer/PauseMenu.unpause()

	add_child(RECRUIT.instance())
	$UILayer.add_child(HUD.instance())
	
	yield(get_tree(), "idle_frame")
	
	for s in get_tree().get_nodes_in_group("SpawnPoints"):
		$Recruit.global_position = s.global_position


func on_viewport_size_changed():
	if viewport_size_ignore:
		return
	print("viewport size changed")
	var viewport_size = get_tree().get_root().size
	
	if viewport_size.y <= 405:
		resolution_scale = 1.0
	elif viewport_size.y <= 675:
		resolution_scale = 2.0
	elif viewport_size.y <= 945:
		resolution_scale = 3.0
	else:
		resolution_scale = 4.0
	
	$UILayer.scale = Vector2(resolution_scale, resolution_scale)
	$Back.scale = Vector2(resolution_scale, resolution_scale)
