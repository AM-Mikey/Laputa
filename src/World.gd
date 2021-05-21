extends Node2D


var save_path = "user://save.dat"
var data = {
	 "player_data" : {},
	"level_data" : {}
	}

export var starting_level = "res://src/Level/DebugLevel.tscn"
onready var current_level = load(starting_level).instance() #assumes current level to start with, might cause issues down the line

func _ready():
	add_child(current_level)
	if $UILayer/TitleScreen.visible == true:
		show_title()
		

func show_title():
	$UILayer/HUD.visible =false
	$Recruit.visible = false
	$Recruit.disabled = true #just as a way to skip physics_process

func _input(event):
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("break"):
		get_tree().quit()
	if event.is_action_pressed("save_data"):
		save_player_data()
		save_level_data()
	if event.is_action_pressed("load_data"):
		load_player_data()
		load_level_data()

func _on_level_change(level, door_index, level_name, music): #clean this up once you get the chance, triggers deserve their own type
	save_level_data()
	$Recruit/Camera2D.smoothing_enabled = false
		
	var level_path = current_level.filename
	current_level.queue_free()
	
	yield(get_tree(), 'idle_frame') #what is this for?
	var next_level = load(level).instance()
	add_child(next_level)
	
		#disable camera if level has one already
	if next_level.has_node("Camera2D"):
		$Recruit/Camera2D.current = false
	else:
		$Recruit/Camera2D.current = true
	
		#get the door with the right index
	var triggers = get_tree().get_nodes_in_group("LevelTrigger")
	for t in triggers:
		if t.level == level_path:
			$Recruit.position = t.position
			print("got right door")
	$UILayer/LevelName.display_text(next_level.level_name)
	
	if next_level.music != music:
		load_music(next_level.music)
		
	$UILayer/MoneyDisplay.visible = false
	
	current_level = next_level
	load_level_data()
	
	#enable smoothing after a bit
	yield(get_tree().create_timer(0.01), "timeout")
	$Recruit/Camera2D.smoothing_enabled = true
	






func load_music(music):
	$MusicPlayer.stream = load(music)
	$MusicPlayer.play()
	
func save_player_data():
	var player = $Recruit
	
	var weapon_data = {}
	
	for w in player.get_node("Weapon/WeaponList").get_children():
		weapon_data[w.name] = {
			"level" : w.level,
			"xp" : w.xp
			}
		if w.needs_ammo:
			weapon_data[w.name]["ammo"] = w.ammo
	
	data["player_data"] = {
		"position" : player.position,
		"hp" : player.hp,
		"max_hp" : player.max_hp,
		"total_xp" : player.total_xp,
		"inventory" : player.inventory,
		"weapon_array" : player.weapon_array,
		"weapon_data" : weapon_data
	}
	
	var file = File.new()
	var file_written = file.open(save_path, File.WRITE)
	if file_written == OK:
		file.store_var(data)
		file.close()
		print("player data saved")
	else:
		print("ERROR: player data cannot be saved!")

func load_player_data():
	var player = $Recruit
	var file = File.new()
	if file.file_exists(save_path):
		var file_read = file.open(save_path, File.READ)
		if file_read == OK:
			var data = file.get_var()
			file.close()
			
			print(data["player_data"])
			
			player.position = data["player_data"]["position"]
			player.hp = data["player_data"]["hp"]
			player.max_hp = data["player_data"]["max_hp"]
			player.total_xp = data["player_data"]["total_xp"]
			player.inventory = data["player_data"]["inventory"]
			player.weapon_array = data["player_data"]["weapon_array"]
			
			player.setup_weapons()
			
			for w in player.get_node("Weapon/WeaponList").get_children():
				w.level = data["player_data"]["weapon_data"][w.name]["level"]
				w.xp = data["player_data"]["weapon_data"][w.name]["xp"]
				if w.needs_ammo:
					w.ammo = data["player_data"]["weapon_data"][w.name]["ammo"]
			
			player.weapon_array[0].update_weapon()
			player.update_hp()
			player.update_max_hp()
			player.update_inventory()
			
			print("player data loaded")
		else:
			print("ERROR: player data cannot be loaded!")
	else:
			print("ERROR: no save file found")

func save_level_data():
	var containers = get_tree().get_nodes_in_group("Containers")
	var containers_if_used = []
	for c in containers:
		containers_if_used.append(c.used)
		
	
	data["level_data"][current_level.name] = {
		"containers_if_used": containers_if_used
	}
	
	var file = File.new()
	var file_written = file.open(save_path, File.WRITE)
	if file_written == OK:
		file.store_var(data)
		file.close()
		print("level data saved")
	else:
		print("ERROR: level data cannot be saved!")

func load_level_data():
	var containers = get_tree().get_nodes_in_group("Container")
	var file = File.new()
	if file.file_exists(save_path):
		var file_read = file.open(save_path, File.READ)
		if file_read == OK:
			var data = file.get_var()
			file.close()
			
			if data["level_data"].has(current_level.name): #if it finds level data for this level
				var current_level_data = data["level_data"][current_level.name]
				if current_level_data["containers_if_used"].empty() == false: #if there are containers in the loaded level
					for i in containers.size():
						containers[i].used = current_level_data["containers_if_used"][i]
						if containers[i].used == true:
							containers[i].get_node("AnimationPlayer").play("Used")
				
				print("level data loaded")
			else:
				print("no previous level data")
		else:
			print("ERROR: level data cannot be loaded!")
	else:
		print("ERROR: no save file found")
