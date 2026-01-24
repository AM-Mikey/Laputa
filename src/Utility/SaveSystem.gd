extends Node

const OPTIONS = preload("res://src/UI/Options/Options.tscn")

var save_path = "user://save.dat"
var temp_path = "user://temp.dat"
var data = {
	"player_data" : {},
	"level_data" : {},
	"mission_data" : {},
	}

@onready var w = get_tree().get_root().get_node("World")



### SAVE ###

func write_player_data_to_save(current_level):
	var pc = f.pc()
	var guns = pc.guns
	var gun_data = {}
	var item_data = []

	for g in guns.get_children():
		gun_data[g.name] = {
			"level" : g.level,
			"xp" : g.xp
			}
		if g.max_ammo != 0:
			gun_data[g.name]["ammo"] = g.ammo

	for i in pc.item_array:
		item_data.append(i.item_name)

	data["player_data"] = {
		"current_level" : current_level.scene_file_path,
		"position" : pc.position,
		"hp" : pc.hp,
		"max_hp" : pc.max_hp,
		"money" : pc.money,
		"gun_data" : gun_data,
		"item_data" : item_data,
	}

	write_to_file(save_path, data)
	print("player data written to save")




func write_level_data_to_temp(current_level):
	var limited_props = []
	for p in get_tree().get_nodes_in_group("LimitedProps"):
		var scoped_data = {
			"name" : p.name,
			"spent" : p.spent
			}
		limited_props.append(scoped_data)

	var limited_triggers = []
	for t in get_tree().get_nodes_in_group("LimitedTriggers"):
		var scoped_data = {
			"name" : t.name,
			"spent" : t.spent
			}
		limited_triggers.append(scoped_data)

	data["level_data"][current_level.level_name] = {
		"limited_props": limited_props,
		"limited_triggers": limited_triggers
	}
	write_to_file(temp_path, data)
	print("level data saved to temp")



func write_mission_data_to_save():
	data["mission_data"] = {
		"main_mission_stage" : ms.main_mission_stage,
		}
	write_to_file(save_path, data)
	print("mission data written to save")


### COPY ###

func copy_level_data_from_save_to_temp():
	var save_data = read_from_file(save_path)
	if !save_data.has("level_data"):
		print("no level data to copy from save to temp")
		return
	var scoped_data = {}
	scoped_data["level_data"] = save_data["level_data"]
	write_to_file(temp_path, scoped_data)
	print("level data copied from save to temp")



func copy_level_data_from_temp_to_save():
	var temp_data = read_from_file(temp_path)
	var save_data = read_from_file(save_path)
	if !temp_data.has("level_data"):
		print("no level data to copy from temp to save")
		return
	var scoped_data = {}
	scoped_data["player_data"] = save_data["player_data"]
	scoped_data["level_data"] = temp_data["level_data"]
	write_to_file(save_path, scoped_data)
	print("level data copied from temp to save")



### LOAD ###

func read_player_data_from_save():
	var scoped_data = read_from_file(save_path)
	var player_data = scoped_data["player_data"]

	w.change_level_via_code(player_data["current_level"])
	await get_tree().process_frame

	var pc = f.pc()
	var guns = pc.guns
	pc.get_node("PlayerCamera").position_smoothing_enabled = false
	pc.position = player_data["position"]
	pc.hp = player_data["hp"]
	pc.max_hp = player_data["max_hp"]
	pc.money = player_data["money"]

	pc.item_array.clear()
	for i in player_data["item_data"]:
		var item_resource = load("res://src/Item/%s.tres" % i)
		pc.item_array.append(item_resource)


	for g in guns.get_children():
		g.free()

	for d in player_data["gun_data"]:
		var gun_scene = load("res://src/Gun/%s" %d + ".tscn")
		if gun_scene == null:
			printerr("ERROR: cannot find gun scene at: res://src/Gun/%s" %d + ".tscn")
			return
		guns.add_child(gun_scene.instantiate())

	for g in guns.get_children():
		g.visible = (g == guns.get_child(0))
		g.level = player_data["gun_data"][g.name]["level"]
		g.xp = player_data["gun_data"][g.name]["xp"]
		if g.max_ammo != 0:
			g.ammo = player_data["gun_data"][g.name]["ammo"]

	pc.emit_signal("hp_updated", pc.hp, pc.max_hp, "load_game")
	pc.emit_signal("guns_updated", guns.get_children(), "load_game")
	pc.emit_signal("money_updated", pc.money)
	#pc.update_inventory()
	pc.emit_signal("invincibility_end")
	print("player data loaded")

	await get_tree().process_frame
	pc.get_node("PlayerCamera").position_smoothing_enabled = true



func read_level_data_from_temp(current_level):
	check_dat_file_presence("save")
	check_dat_file_presence("temp")
	var scoped_data = read_from_file(temp_path)
		#return
	if !scoped_data["level_data"].has(current_level.level_name):
		print("no previous level data in temp")
		return
	var current_level_data = scoped_data["level_data"][current_level.level_name]
	set_props_spent(current_level_data["limited_props"])
	set_triggers_spent(current_level_data["limited_triggers"])
	print("level data loaded from temp")



func read_level_data_from_save(current_level):
	var scoped_data = read_from_file(save_path)
	if !scoped_data["level_data"].has(current_level.level_name):
		print("no previous level data in save")
		return
	var current_level_data = scoped_data["level_data"][current_level.level_name]
	set_props_spent(current_level_data["limited_props"])
	set_triggers_spent(current_level_data["limited_triggers"])
	print("level data loaded from save")



func read_mission_data_from_save():
	var scoped_data = read_from_file(save_path)
	ms.main_mission_stage = scoped_data["main_mission_stage"]
	print("mission data loaded from save")



#### HELPER ###

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


##checks if the given file exists, if not duplicate from res://defaults/
func check_dat_file_presence(filename:String) -> void:
		#temp file
	var defaultfile_path = "res://defaults/" + filename + ".dat"
	var userfile_path = "user://" + filename + ".dat"

	if FileAccess.file_exists(userfile_path):
		return
	else:
		DirAccess.copy_absolute(defaultfile_path,userfile_path)


func set_props_spent(limited_props):
	await get_tree().create_timer(0.01).timeout #wait for props to spawn
	for saved in limited_props:
		for current in get_tree().get_nodes_in_group("LimitedProps"):
			if saved["name"] == current.name:
				if saved["spent"]:
					current.spent = true
					current.expend_prop()

func set_triggers_spent(limited_triggers):
	await get_tree().create_timer(0.01).timeout #wait for triggers to spawn
	for saved in limited_triggers:
		for current in get_tree().get_nodes_in_group("LimitedTriggers"):
			if saved["name"] == current.name:
				if saved["spent"]:
					await get_tree().process_frame
					current.spent = true
					current.expend_trigger()



### OPTIONS ###

func load_options():
	var options = OPTIONS.instantiate()
	options.ishidden = true
	w.ml.add_child(options)
	options.tabs.get_node("Settings").load_settings()
	options.tabs.get_node("KeyConfig").rm.load_input_map() #TODO: migrate to Inputconfig script
	#options.tabs.get_node("ControllerConfig").load_input_map()
	await get_tree().process_frame
	options.queue_free()
