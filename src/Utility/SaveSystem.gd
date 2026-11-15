extends Node

const OPTIONS = preload("res://src/UI/Options/Options.tscn")

var first_time_loading_settings := true
var save_path: String:
	get: return "user://save_%d.dat" % current_slot
var temp_path = "user://temp.dat"
var save_slot_pointer_path = "user://save_slot_pointer.dat"
var data = {
	"player_data" : {},
	"level_data" : {},
	"mission_data" : {},
	"dialog_data" : {},
	"other_data" : {},
	}
var current_slot := -1 #set by world.gd/first_time_level_setup and /setup_title_and_background
var has_save := false

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
		item_data.append(i.resource_path)

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



func write_mission_data_to_save(): #TODO: last session moved this to trigger save and load last, verify this works
	var side_missions_deconstructed = {}
	for m in ms.side_missions:
		side_missions_deconstructed[m.resource_path] = m.current_stage
	data["mission_data"] = {
		"main_mission_stage" : ms.main_mission_stage,
		"side_missions_deconstructed" : side_missions_deconstructed,
		"mission_progress_history" : ms.mission_progress_history,
		}
	write_to_file(save_path, data)
	print("mission data written to save")



func write_dialog_data_to_temp(current_level, npc):
	if !data["dialog_data"].has(current_level.level_name): #create the specific level if not
		data["dialog_data"][current_level.level_name] = {}
	data["dialog_data"][current_level.level_name][npc.id] = [npc.conversation_queue, npc.side_conversation_queue]
	write_to_file(temp_path, data)
	print("dialog data saved to temp")



func write_other_data_to_save(): #misc system data, not saved in temp
	data["other_data"]["unix_time"] = Time.get_unix_time_from_system()
	data["other_data"]["uptime"] = Uptime.get_total_uptime()
	write_to_file(save_path, data)



### COPY ###

func copy_level_and_dialog_data_from_save_to_temp():
	var save_data = read_from_file(save_path)
	if !save_data.has("level_data"):
		print("no level data to copy from save to temp")
	if !save_data.has("dialog_data"):
		print("no dialog data to copy from save to temp")
	var scoped_data = {}
	scoped_data["level_data"] = save_data["level_data"]
	scoped_data["dialog_data"] = save_data["dialog_data"]
	write_to_file(temp_path, scoped_data)
	print("level and dialog data copied from save to temp")



func copy_level_and_dialog_data_from_temp_to_save():
	var temp_data = read_from_file(temp_path)
	var save_data = read_from_file(save_path)
	if !temp_data.has("level_data"):
		print("no level data to copy from temp to save")
	if !temp_data.has("dialog_data"):
		print("no dialog data to copy from temp to save")
	var scoped_data = {}
	scoped_data["player_data"] = save_data["player_data"]
	scoped_data["level_data"] = temp_data["level_data"]
	scoped_data["mission_data"] = save_data["mission_data"]
	scoped_data["dialog_data"] = temp_data["dialog_data"]
	write_to_file(save_path, scoped_data)
	print("level and dialog data copied from temp to save")



### LOAD ###

func read_mission_data_from_save():
	var scoped_data = read_from_file(save_path)
	var mission_data = scoped_data["mission_data"]
	ms.main_mission_stage = mission_data["main_mission_stage"]
	ms.side_missions = []
	for path in mission_data["side_missions_deconstructed"].keys():
		var side_mission = load(path)
		side_mission.current_stage = mission_data["side_missions_deconstructed"][path] #the key's value is the current stage
		ms.side_missions.append(side_mission)
	ms.mission_progress_history = mission_data["mission_progress_history"]
	print("mission data loaded from save")



func read_player_data_from_save():
	var scoped_data = read_from_file(save_path)
	var player_data = scoped_data["player_data"]

	w.change_level_via_code(player_data["current_level"], true)
	await get_tree().process_frame

	var pc = f.pc()
	var guns = pc.guns
	pc.get_node("PlayerCamera").reset()
	pc.position = player_data["position"]
	pc.hp = player_data["hp"]
	pc.max_hp = player_data["max_hp"]
	pc.money = player_data["money"]

	pc.item_array.clear()
	for i in player_data["item_data"]:
		var item_resource = load(i)
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



func read_level_data_from_temp(current_level):
	#check_dat_file_presence("save")
	#check_dat_file_presence("temp")
	var scoped_data = read_from_file(temp_path)
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



func read_dialog_data_from_temp(current_level):
	#check_dat_file_presence("save")
	#check_dat_file_presence("temp")
	var scoped_data = read_from_file(temp_path)
	if !scoped_data["dialog_data"].has(current_level.level_name):
		print("no previous dialog data in temp")
		return
	var current_level_data = scoped_data["dialog_data"][current_level.level_name]
	for id in current_level_data:
		for npc in get_tree().get_nodes_in_group("NPCs"):
			if npc.id.nocasecmp_to(id) == 0:
				npc.conversation_queue = current_level_data[id][0]
				npc.side_conversation_queue = current_level_data[id][1]
	print("dialog data loaded from temp")


func read_dialog_data_from_save(current_level):
	var scoped_data = read_from_file(save_path)
	if !scoped_data["dialog_data"].has(current_level.level_name):
		print("no previous dialog data in save")
		return
	var current_level_data = scoped_data["dialog_data"][current_level.level_name]
	for id in current_level_data:
		for npc in get_tree().get_nodes_in_group("NPCs"):
			if npc.id.nocasecmp_to(id) == 0:
				npc.conversation_queue = current_level_data[id][0]
				npc.side_conversation_queue = current_level_data[id][1]
	print("dialog data loaded from save")


func read_other_data_from_save(): #misc system data, not saved in temp
	var scoped_data = read_from_file(save_path)
	Uptime.start_tracking_uptime(scoped_data["other_data"]["uptime"])
	print("other data loaded from save")

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
#func check_dat_file_presence(filename:String) -> void:
		##temp file
	#var defaultfile_path = "res://defaults/" + filename + ".dat"
	#var userfile_path = "user://" + filename + ".dat"
#
	#if FileAccess.file_exists(userfile_path):
		#return
	#else:
		#DirAccess.copy_absolute(defaultfile_path,userfile_path)

func get_save_file_indices() -> Array[int]:
	var out: Array[int] = []
	var prefix =  "save_"
	var dir := DirAccess.open("user://")
	if dir == null:
		printerr("ERROR: Could not open user folder")
		return([-1])
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if !dir.current_is_dir():
			if file_name.begins_with(prefix):
				var index: int = int(file_name.get_basename().trim_prefix(prefix))
				out.append(index)
		file_name = dir.get_next()
	dir.list_dir_end()
	return out

func get_last_valid_slot() -> int:
	var out := -1
	var latest_unix_time := 0
	if !FileAccess.file_exists(save_slot_pointer_path):
		var save_file_indices = get_save_file_indices()
		if save_file_indices.size() == 0:
			print("no save files found")
			return out #-1, no save files
		else:
			print("no save slot pointer file found, getting highest index save slot")
			out = get_save_file_indices()[-1] #last one
			return out

	var save_slot_pointer_array = read_from_file(save_slot_pointer_path)
	for i in save_slot_pointer_array:
		if int(i[1]) >= latest_unix_time:
			latest_unix_time = int(i[1])
			out = int(i[0])
	return out

func write_save_slot_pointer():
	var save_slot_pointer_data = {}
	save_slot_pointer_data["current_slot"] = current_slot
	save_slot_pointer_data["utc_time"] = Time.get_unix_time_from_system()
	write_to_file(save_slot_pointer_path, save_slot_pointer_data)
	print("wrote save slot pointer")


func set_props_spent(limited_props):
	await get_tree().create_timer(0.01, true, false).timeout #wait for props to spawn #TODO: check if these flags are correct
	for saved in limited_props:
		for current in get_tree().get_nodes_in_group("LimitedProps"):
			if saved["name"] == current.name:
				if saved["spent"]:
					current.spent = true
					current.expend_prop()

func set_triggers_spent(limited_triggers):
	await get_tree().create_timer(0.01, true, false).timeout #wait for triggers to spawn #TODO: check if these flags are correct
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
