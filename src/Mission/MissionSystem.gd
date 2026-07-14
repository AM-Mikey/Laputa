extends Node

const INVENTORY_ICON = preload("res://src/UI/Inventory/InventoryIcon.tscn")

const MAIN_MISSION = [ #[name, trigger_type, trigger_value, description]
	["talk_npc_a", "", "",
	"I need to talk to NPC A"],
	["talk_npc_b", "", "",
	"I need to talk to NPC B"],
	["talk_npc_c", "", "",
	"I need to talk to NPC C"],
	["talk_npc_d", "", "",
	"I need to talk to NPC D"],
	["celebrate", "", "",
	"I've completed the mission demo!"],
	["camera_test", "prop_activate", "lamp",
	"This is a test of the manual camera controls"],
	["camera_test_2", "", "",
	"This is a test of the manual camera controls, part 2"],
	["dialog_system_demo_start", "", "",
	"Start demo"],
	["textbox_demo", "", "",
	"Textbox related dialog commands demo"],
	["dialog_branching_demo", "", "",
	"Dialog branching dialog commands demo"],
	["entity_demo", "", "",
	"Entity related dialog commands demo"],
	["camera_demo", "", "",
	"camera related dialog commands demo"],
]

var main_mission_stage: Array = MAIN_MISSION[0]
var side_missions: Array[SideMission]
var mission_progress_history: Array = [["Main", MAIN_MISSION[0][0]]] #[[MissionName, stage_string]] ##start with first main mission

@onready var w = get_tree().get_root().get_node("World")

func progress_main_mission(): #no protection for index > # of stages
	var current_index = MAIN_MISSION.find(main_mission_stage)
	main_mission_stage = MAIN_MISSION[current_index + 1]
	mission_progress_history.append(["Main", main_mission_stage[0]])
	print("Main mission progress, new stage: " + main_mission_stage[0])
	update_level_via_mission()

#func seek_main_mission(seek_value): #no protection for correct seek_value #TODO: needs to iterate through all middle stages for this to work
	#main_mission_stage = seek_value
	#print("Main mission seek, new stage: " + main_mission_stage[0])
	#update_level_via_mission()

func progress_side_mission(mission_name): #no protection for index > # of stages
	var mission = mission_name_to_mission(mission_name)
	var current_index: int
	var index := 0
	for s in mission.stages:
		if s[0] == mission.current_stage:
			current_index = index
		index += 1
	mission.current_stage = mission.stages[current_index + 1][0]
	mission_progress_history.append([mission.resource_path.get_file().trim_suffix(".tres"), mission.current_stage[0]])
	print("Side mission %s progress, new stage: " %mission_name + mission.current_stage)
	update_level_via_mission(mission_name)
	mission_progress_check()

func start_side_mission(mission_name):
	var is_duplicate := false
	for m in side_missions:
		if m.resource_path.get_file().trim_suffix(".tres") == mission_name:
			is_duplicate = true
	if !is_duplicate:
		side_missions.append(load("res://src/Mission/%s.tres" %mission_name))
		var mission = mission_name_to_mission(mission_name)
		mission_progress_history.append([mission.resource_path.get_file().trim_suffix(".tres"), mission.current_stage[0]])
		update_level_via_mission(mission_name)
		mission_progress_check()
		var inventory_icon = INVENTORY_ICON.instantiate()
		inventory_icon.type = "Mission"
		w.ui.add_child(inventory_icon)

#func seek_side_mission(mission_name, seek_value): #no protection for correct seek_value #TODO: needs to iterate through all middle stages for this to work
	#var mission = mission_name_to_mission(mission_name)
	#mission.current_stage = seek_value
	#print("Side mission %s seek, new stage: " %mission_name + mission.current_stage)
	#update_level_via_mission(mission_name)
	#mission_progress_check()

func end_side_mission(mission_name):
	var mission = mission_name_to_mission(mission_name)
	mission.current_stage = "complete"
	print("Side mission %s completed" %mission_name)

	update_level_via_mission(mission_name)


func mission_progress_check(passed_variable = null):
	#side missions
	for m in ms.side_missions:
		var stage: Array
		for s in m.stages:
			if s[0] == m.current_stage:
				stage = s
		_progress_from_check("side", m, stage, passed_variable)
	#main mission
	_progress_from_check("main", "main",ms.main_mission_stage, passed_variable)

func _progress_from_check(type: String, mission, stage, passed_variable):
	var do_progress = false
	if stage.size() >= 3: #has trigger and value
		match stage[1]:
			"item": #search inventory for item
				for i in f.pc().item_array:
					if stage[2].to_pascal_case() == i.resource_path.get_file().trim_suffix(".tres"):
						do_progress = true
			"gun": #search guns for gun
				for g in f.pc().guns:
					if stage[2].to_pascal_case() == g.name:
						do_progress = true
			"topic": #search topic array for topic
				for t in f.pc().topic_array:
					if stage[2].to_pascal_case() == t.topic_name:
						do_progress = true
			"level_enter": #check if we entered the level with the given name
				if stage[2].to_pascal_case() ==  w.current_level.name:
					do_progress = true
			"boss_defeat": #check if we defeated a boss
				pass
			"prop_activate": #check if a prop was activated
				if passed_variable:
					if stage[2].to_pascal_case() == passed_variable.to_pascal_case():
						do_progress = true
	if do_progress:
		match type:
			"main": ms.progress_main_mission()
			"side": ms.progress_side_mission(mission.resource_path.get_file().trim_suffix(".tres"))



func setup_level_from_array(array, update_conversations, is_entering):
	for i in array:
		var mission_name = i[0]
		var mission_stage = i[1]
		update_level_via_mission(mission_name, mission_stage, update_conversations, is_entering) #don't update conversations, instead we load them from save

func setup_level_from_mission_progress_history():
	print("from history")
	for i in mission_progress_history:
		var mission_name = i[0]
		var mission_stage = i[1]
		update_level_via_mission(mission_name, mission_stage, true, true)  #don't update conversations, instead we load them from save


func update_level_via_mission(mission_name = "Main", mission_stage = "current", update_conversations = true, is_entering = false):
	var json = load(w.current_level.mission_level_update)
	var data = json.get_data()
	if mission_stage == "current":
		if mission_name == "Main":
			mission_stage = main_mission_stage[0]
		else:
			mission_stage = mission_name_to_mission(mission_name).current_stage


#set_spawn
	var enemy_spawn_dict = get_matching_entities_values(data, mission_name, mission_stage, "enemy_set_spawn", "EnemySpawns", true)
	for k in enemy_spawn_dict.keys():
		if enemy_spawn_dict[k]: #spawn
			if !get_has_entity_with_id("Enemies", k.properties["id"][0]):
				k.allow_spawn = true
				k.spawn()
		else: #free
			var enemy_free_dict = get_matching_entities_values(data, mission_name, mission_stage, "enemy_set_spawn", "Enemies", false)
			for l in enemy_free_dict.keys():
				l.free() #l.die(true) #TODO: poof effect? idk #free is faster for cases where we need to do it repeatedly on off, otherwise get_has_entity_with_id has a false positive when it flashes through all of the mission stages when loading a save file
			k.allow_spawn = false

	var npc_spawn_dict = get_matching_entities_values(data, mission_name, mission_stage, "npc_set_spawn", "NPCSpawns", true)
	for k in npc_spawn_dict.keys():
		if npc_spawn_dict[k]: #spawn
			if !get_has_entity_with_id("NPCs", k.properties["id"][0]):
				k.allow_spawn = true
				k.spawn()
		else: #free
			var npc_free_dict = get_matching_entities_values(data, mission_name, mission_stage, "npc_set_spawn", "NPCs", false)
			for l in npc_free_dict.keys():
				l.free()
			k.allow_spawn = false

	var prop_spawn_dict = get_matching_entities_values(data, mission_name, mission_stage, "prop_set_spawn", "PropSpawns", true)
	for k in prop_spawn_dict.keys():
		if prop_spawn_dict[k]: #spawn
			if !get_has_entity_with_id("Props", k.properties["id"][0]):
				k.allow_spawn = true
				k.spawn()
		else: #free
			var prop_free_dict = get_matching_entities_values(data, mission_name, mission_stage, "prop_set_spawn", "Props", false)
			for l in prop_free_dict.keys():
				l.free()
			k.allow_spawn = false

	var trigger_spawn_dict = get_matching_entities_values(data, mission_name, mission_stage, "trigger_set_spawn", "TriggerSpawns", true)
	for k in trigger_spawn_dict.keys():
		if trigger_spawn_dict[k]: #spawn
			if !get_has_entity_with_id("Triggers", k.properties["id"][0]):
				k.allow_spawn = true
				k.spawn()
		else: #free
			var trigger_free_dict = get_matching_entities_values(data, mission_name, mission_stage, "trigger_set_spawn", "Triggers", false)
			for l in trigger_free_dict.keys():
				l.free()
			k.allow_spawn = false


#position
	var enemy_position_dict = get_matching_entities_values(data, mission_name, mission_stage, "enemy_position", "Enemies", false)
	for k in enemy_position_dict.keys():
		k.global_position = array_to_vector2(enemy_position_dict[k])

	var npc_position_dict = get_matching_entities_values(data, mission_name, mission_stage, "npc_position", "NPCs", false)
	for k in npc_position_dict.keys():
		k.global_position = array_to_vector2(npc_position_dict[k])

	var prop_position_dict = get_matching_entities_values(data, mission_name, mission_stage, "prop_position", "Props", false)
	for k in prop_position_dict.keys():
		k.global_position = array_to_vector2(prop_position_dict[k])

	var trigger_position_dict = get_matching_entities_values(data, mission_name, mission_stage, "trigger_position", "Triggers", false)
	for k in trigger_position_dict.keys():
		k.global_position = array_to_vector2(trigger_position_dict[k])


#position_offset
	var enemy_position_offset_dict = get_matching_entities_values(data, mission_name, mission_stage, "enemy_position_offset", "Enemies", false)
	for k in enemy_position_offset_dict.keys():
		k.global_position += array_to_vector2(enemy_position_offset_dict[k])

	var npc_position_offset_dict = get_matching_entities_values(data, mission_name, mission_stage, "npc_position_offset", "NPCs", false)
	for k in npc_position_offset_dict.keys():
		k.global_position += array_to_vector2(npc_position_offset_dict[k])

	var prop_position_offset_dict = get_matching_entities_values(data, mission_name, mission_stage, "prop_position_offset", "Props", false)
	for k in prop_position_offset_dict.keys():
		k.global_position += array_to_vector2(prop_position_offset_dict[k])

	var trigger_position_offset_dict = get_matching_entities_values(data, mission_name, mission_stage, "trigger_position_offset", "Triggers", false)
	for k in trigger_position_offset_dict.keys():
		k.global_position += array_to_vector2(trigger_position_offset_dict[k])


	if update_conversations:
		#npc_set_main_conversation_queue
		var npc_set_main_conversation_queue = get_matching_entities_values(data, mission_name, mission_stage, "npc_set_main_conversation_queue", "NPCs", false)
		for k in npc_set_main_conversation_queue.keys():
			var queue_to_add = get_conversation_queue_from_mixed_or_partial(npc_set_main_conversation_queue[k])
			var first_added_conversation_index = k.conversation_queue.size()
			for i in k.conversation_queue.size(): #this doesnt actually set, just sets all previous convo to already_read
				k.conversation_queue[i][4] = true
			for c in queue_to_add:
				k.conversation_queue.append(c)
			k.next_conversation_queue_name = "conversation_queue"
			k.next_conversation_index = first_added_conversation_index

		#npc_append_conversation_queue
		var npc_append_conversation_queue_dict = get_matching_entities_values(data, mission_name, mission_stage, "npc_append_conversation_queue", "NPCs", false)
		for k in npc_append_conversation_queue_dict.keys():
			var convo_queue = get_conversation_queue_from_mixed_or_partial(npc_append_conversation_queue_dict[k])
			for a in convo_queue:
				match a[1]:
					"main": k.conversation_queue.append(a)
					"side": k.side_conversation_queue.append(a)
				SaveSystem.write_dialog_data_to_temp(w.current_level, k)

#level_conversation_on_enter
	if data.has("level_conversation_on_enter"):
		if data["level_conversation_on_enter"].has(mission_name):
			for stage in data["level_conversation_on_enter"][mission_name]:
				if stage == mission_stage:
					w.current_level.conversation_on_enter = data["level_conversation_on_enter"][mission_name][stage]

#camera_control_add
	if !is_entering:
		if data.has("camera_control_add"):
			if data["camera_control_add"].has(mission_name):
				for stage in data["camera_control_add"][mission_name]:
					if stage == mission_stage:
						#inp.can_act = false
						for a in data["camera_control_add"][mission_name][stage]:
							f.pc().get_node("PlayerCamera").control_add(a)

### HELPER ###

func get_matching_entities_values(data, mission_name, mission_stage, data_key, group, is_spawn) -> Dictionary:
	var out = {} #node, value
	if !data.has(data_key):
		return out
	if !data[data_key].has(mission_name):
		return out
	for id in data[data_key][mission_name]:
		for n in get_tree().get_nodes_in_group(group):
			var correct_id = false
			if is_spawn:
				if n.properties["id"][0] == id: correct_id = true
			else:
				if n.id == id: correct_id = true
			if correct_id:
				if data[data_key][mission_name][id].has(mission_stage):
					out[n] = data[data_key][mission_name][id][mission_stage]
				elif data[data_key][mission_name][id].has("any"):
					out[n] = data[data_key][mission_name][id]["any"]
	return out


func get_has_entity_with_id(entity_group: String, id):
	for e in get_tree().get_nodes_in_group(entity_group):
		if e.id == id:
			printerr("ERROR: entity with id: ", id, " already exists!")
			return true
	return false


func array_to_vector2(array) -> Vector2:
	return Vector2(array[0], array[1])


func mission_name_to_mission(mission_name) -> SideMission:
	var out: SideMission
	for m in side_missions:
		if m.resource_path.get_file().trim_suffix(".tres") == mission_name:
			out = m
	return out

func get_conversation_queue_from_mixed_or_partial(mixed_or_partial) -> Array:
	var out = []
	if mixed_or_partial is String:
		out = [[mixed_or_partial, "main", false, true, false]]
	elif mixed_or_partial is Array:
		#if mixed_or_partial == [] or mixed_or_partial == [[]]: Don't clear like this anymore. probably just set repeating to false instead?
			#out = [[]]
			#return out
		match mixed_or_partial[0].size(): #if array, how abbreviated is it? take the first as an example
			1:
				for a in mixed_or_partial:
					out.append([a[0], "main", false, true, false])
			2:
				for a in mixed_or_partial:
					out.append([a[0], a[1], false, true, false])
			3:
				for a in mixed_or_partial:
					out.append([a[0], a[1], a[2], true, false])
			4:
				for a in mixed_or_partial:
					out.append([a[0], a[1], a[2], a[3], false])
			5:
				out = mixed_or_partial
			_: printerr("ERROR: Too many indices in conversation_queue array")
	return out
