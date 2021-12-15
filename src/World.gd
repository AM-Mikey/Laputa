extends Node2D

const DEBUG_INFO = preload("res://src/UI/Debug/DebugInfo.tscn")
const HUD = preload("res://src/UI/HUD/HUD.tscn")
const INVENTORY = preload("res://src/UI/Inventory/Inventory.tscn")
const LEVELNAME = preload("res://src/UI/LevelName.tscn")
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
export var is_release: bool = false
export var should_skip_title: bool = false

export var starting_level = "res://src/Level/Village/Village.tscn"
onready var current_level = load(starting_level).instance() #assumes current level to start with, might cause issues down the line

func _ready():
	var _err = get_tree().root.connect("size_changed", self, "on_viewport_size_changed")
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
	on_level_change(starting_level, 0, "LevelSelect", "res://assets/Music/XXXX.ogg")
	add_child(RECRUIT.instance())
	get_node("UILayer").add_child(HUD.instance())
	
	var spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	for s in spawn_points:
		get_node("Recruit").position = s.global_position


func _input(event):
	if Input.is_action_just_pressed("debug_print"):
		debug_print()
	if event.is_action_pressed("reload"):
		var _err = get_tree().reload_current_scene()
	if event.is_action_pressed("save_data"):
		var popup = POPUP.instance()
		popup.text = "quicksaved..."
		$UILayer.add_child(popup)
		save_level_data_to_temp()
		save_player_data_to_save()
		copy_level_data_to_save()
	if event.is_action_pressed("load_data"):
		var popup = POPUP.instance()
		popup.text = "loaded save"
		$UILayer.add_child(popup)
		load_player_data_from_save()
		load_level_data_from_save()
		copy_level_data_to_temp()
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
			



#TODO: can we remove level_name safely? It is unused
func on_level_change(level, door_index, _level_name, music):
	print("level change")
	save_level_data_to_temp()
	
	if $UILayer.has_node("DialogBox"):
		$UILayer/DialogBox.stop_printing()
	clear_spawn_layers()
	clear_bg_layer()
	
	var level_path = current_level.filename
	current_level.queue_free()
	
	yield(get_tree(), 'idle_frame') #what is this for?
	var next_level = load(level).instance()
	add_child(next_level)
	
	if has_node("Recruit"):
		$Recruit/PlayerCamera.smoothing_enabled = false
		$Recruit/PlayerCamera.current = not next_level.has_node("Camera2D") #turn off camera if level has one already
		

	
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
		$Recruit.disabled = false
		
		if $UILayer.has_node("LevelName"):
			$UILayer/LevelName.free()
		
		var level_name_ui = LEVELNAME.instance()
		level_name_ui.text = next_level.name #in final version switch this to display name
		level_name_ui.wait_time = 0.6
		$UILayer.add_child(level_name_ui)
		
	#DOORS
	elif $UILayer.has_node("TransitionIris"):
		yield(get_tree().create_timer(0.4), "timeout")
		$UILayer/TransitionIris.play_out_animation()
		already_enabled = true
		$Recruit.disabled = false
		
		if $UILayer.has_node("LevelName"):
			$UILayer/LevelName.free()
		
		var level_name_ui = LEVELNAME.instance()
		level_name_ui.text = next_level.name #in final version switch this to display name
		level_name_ui.wait_time = 0.6
		$UILayer.add_child(level_name_ui)
		
		
	######
	if not already_enabled:
		$Recruit.disabled = false
		
	if $UILayer.has_node("LevelName"):
		$UILayer/LevelName.free()
	var level_name_ui = LEVELNAME.instance()
	level_name_ui.text = next_level.name #in final version switch this to display name
	$UILayer.add_child(level_name_ui)
	
	
	
	if next_level.music != music:
		load_music(next_level.music)
		
	
	current_level = next_level
	load_level_data_from_temp()
	
	#enable smoothing after a bit
	yield(get_tree().create_timer(0.01), "timeout")
	$Recruit/PlayerCamera.smoothing_enabled = true
	
	
	
	#enable player collision after a bit more ## why?
	yield(get_tree().create_timer(0.1), "timeout")
	$Recruit.set_collision_layer_bit(0, true)
	
	
func load_music(music):
	if music:
		$MusicPlayer.stream = load(music)
		$MusicPlayer.play()
	
func save_player_data_to_save():
	var player = $Recruit
	
	var weapon_data = {}
	
	for w in player.weapon_array:
		weapon_data[w.resource_name] = {
			"level" : w.level,
			"xp" : w.xp
			}
		if w.needs_ammo:
			weapon_data[w.resource_name]["ammo"] = w.ammo
	
	data["player_data"] = {
		"current_level" : current_level.filename,
		"position" : player.position,
		"hp" : player.hp,
		"max_hp" : player.max_hp,
		"total_xp" : player.total_xp,
		"inventory" : player.inventory,
		#"weapon_array" : player.weapon_array,
		"weapon_data" : weapon_data
	}
	
	var file = File.new()
	var file_written = file.open(save_path, File.WRITE)
	if file_written == OK:
		file.store_var(data)
		file.close()
		print("player data saved")
	else:
		printerr("ERROR: player data could not be saved!")

func load_player_data_from_save():
	var pc = $Recruit
	var file = File.new()
	if file.file_exists(save_path):
		var file_read = file.open(save_path, File.READ)
		if file_read == OK:
			var scoped_data = file.get_var()
			file.close()
			
			print(scoped_data["player_data"])
			
			on_level_change(scoped_data["player_data"]["current_level"], null, null, null)
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

func save_level_data_to_temp():
	var containers_if_used = []
	for c in get_tree().get_nodes_in_group("Containers"):
		containers_if_used.append(c.used)
		
	
	data["level_data"][current_level.name] = {
		"containers_if_used": containers_if_used
	}
	
	var file = File.new()
	var file_written = file.open(temp_path, File.WRITE)
	if file_written == OK:
		file.store_var(data)
		file.close()
		print("level data saved to temp")
	else:
		printerr("ERROR: level data could not be saved to temp!")

func copy_level_data_to_temp():
		var success_check = 0
		var _temp_data
		var save_data
		
		var file = File.new()
		
		
		var file_read = file.open(save_path, File.READ)
		if file_read == OK:
			save_data = file.get_var()
			file.close()
			success_check += 1
		else:
			printerr("ERROR: data could not be loaded from save while copying!")
			
		
		file_read = file.open(temp_path, File.READ)
		if file_read == OK:
			_temp_data = file.get_var()
			file.close()
			success_check += 1
		else:
			printerr("ERROR: data could not be loaded from temp while copying")
			
		

	
		if save_data.has("level_data"):
			var scoped_data = {}
			scoped_data["level_data"] = save_data["level_data"]
			
			var file_written = file.open(temp_path, File.WRITE)
			if file_written == OK:
				file.store_var(scoped_data)
				file.close()
				success_check +=1
			else:
				printerr("ERROR: data could not be saved to temp while copying!")
				return
		
		else:
			print("no level data to copy from save to temp")
			return
			
			
			
			
			
		if success_check == 3:
			print("level data copied from save to temp")
		else:
			printerr("ERROR: level data could not be copied from save to temp!")
	
func copy_level_data_to_save():
		var success_check = 0
		var temp_data
		var save_data
		
		var temp_file = File.new()
		var temp_file_read = temp_file.open(temp_path, File.READ)
		if temp_file_read == OK:
			temp_data = temp_file.get_var()
			temp_file.close()
			success_check += 1
		else:
			printerr("ERROR: data could not be loaded from temp while copying!")
			return
			
		var save_file = File.new()
		var save_file_read = save_file.open(save_path, File.READ)
		if save_file_read == OK:
			save_data = save_file.get_var()
			save_file.close()
			success_check += 1
		else:
			printerr("ERROR: data could not be loaded from save while copying!")
			return
			
			
		if temp_data.has("level"):
			var scoped_data = {}
			scoped_data["player_data"] = save_data["player_data"]
			scoped_data["level_data"] = temp_data["level_data"]
			
			var save_file_written = save_file.open(save_path, File.WRITE)
			if save_file_written == OK:
				save_file.store_var(scoped_data)
				save_file.close()
				success_check +=1
			else:
				printerr("ERROR: data could not be saved to save while copying!")
				return
		
		else:
			print("no level data to copy from temp to save")
			return
		
		
		
		if success_check == 3:
			print("level data copied from temp to save")
		else:
			printerr("ERROR: level data could not be copied from temp to save!")


func load_level_data_from_temp():
	var containers = get_tree().get_nodes_in_group("Containers")
	var file = File.new()
	if file.file_exists(temp_path):
		var file_read = file.open(temp_path, File.READ)
		if file_read == OK:
			var scoped_data = file.get_var()
			file.close()
			
			if scoped_data["level_data"].has(current_level.name): #if it finds level data for this level
				var current_level_data = scoped_data["level_data"][current_level.name]
				if current_level_data["containers_if_used"].empty() == false: #if there are containers in the loaded level
					for i in containers.size():
						containers[i].used = current_level_data["containers_if_used"][i]
						if containers[i].used == true:
							containers[i].get_node("AnimationPlayer").play("Used")
				
				print("level data loaded from temp")
			else:
				print("no previous level data in temp")
		else:
			printerr("ERROR: level data could not be loaded from temp!")
	else:
		printerr("ERROR: no temp file found")

func load_level_data_from_save():
	var containers = get_tree().get_nodes_in_group("Containers")
	var file = File.new()
	if file.file_exists(save_path):
		var file_read = file.open(save_path, File.READ)
		if file_read == OK:
			var scoped_data = file.get_var()
			file.close()
			
			if scoped_data["level_data"].has(current_level.name): #if it finds level data for this level
				var current_level_data = scoped_data["level_data"][current_level.name]
				if current_level_data["containers_if_used"].empty() == false: #if there are containers in the loaded level
					for i in containers.size():
						containers[i].used = current_level_data["containers_if_used"][i]
						if containers[i].used == true:
							containers[i].get_node("AnimationPlayer").play("Used")
				
				print("level data loaded from save")
			else:
				print("no previous level data in save")
		else:
			printerr("ERROR: level data could not be loaded from save!")
	else:
		printerr("ERROR: no save file found")

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
