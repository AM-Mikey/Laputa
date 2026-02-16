extends Node

const MAIN_MISSION = [
	"talk_npc_a",
	"talk_npc_b",
	"talk_npc_c",
	"talk_npc_d",
	"celebrate",
]


var main_mission_stage: String = MAIN_MISSION.front()

var side_missions: Array[SideMission]

@onready var w = get_tree().get_root().get_node("World")

func progress_main_mission(): #no protection for index > # of stages
	var current_index = MAIN_MISSION.find(main_mission_stage)
	main_mission_stage = MAIN_MISSION[current_index + 1]
	print("Main mission progress, new stage: " + main_mission_stage)
	update_level_via_mission()

func seek_main_mission(seek_value): #no protection for correct seek_value
	main_mission_stage = seek_value
	print("Main mission seek, new stage: " + main_mission_stage)
	update_level_via_mission()

func progress_side_mision(mission_name): #no protection for index > # of stages
	var mission = mission_name_to_mission(mission_name)
	var current_index: int
	var index := 0
	for s in mission.stages:
		if s[0] == mission.current_stage:
			current_index = index
		index += 1
	mission.current_stage = mission.stages[current_index + 1][0]
	print("Side mission %s progress, new stage: " %mission_name + mission.current_stage)
	update_level_via_mission(mission_name)
	mission_progress_check()

func seek_side_mission(mission_name, seek_value): #no protection for correct seek_value
	var mission = mission_name_to_mission(mission_name)
	mission.current_stage = seek_value
	print("Side mission %s seek, new stage: " %mission_name + mission.current_stage)
	update_level_via_mission(mission_name)
	mission_progress_check()

func end_side_mission(mission_name):
	var mission = mission_name_to_mission(mission_name)
	side_missions.erase(mission)
	print("Side mission %s completed" %mission_name)


func mission_progress_check(): #TODO: for main mission too
	print("checking")
	for m in ms.side_missions:
		var stage: Array
		for s in m.stages:
			if s[0] == m.current_stage:
				stage = s
		if stage.size() == 3: #has trigger and value
			if stage[1] == "item": #search inventory for item
				for i in f.pc().item_array:
					if stage[2].to_pascal_case() == i.resource_path.get_file().trim_suffix(".tres"):
						print("GOTEEEM")
						ms.progress_side_mision(m.resource_path.get_file().trim_suffix(".tres"))


func update_level_via_mission(mission_name = "Main"): #while already in level
	var json = load(w.current_level.mission_level_update)
	var data = json.get_data()

#spawn
	var enemy_spawn_dict = get_matching_entities_values(data, mission_name, "enemy_spawn", "EnemySpawns", true)
	for k in enemy_spawn_dict.keys():
		k.allow_spawn = enemy_spawn_dict[k]
		k.spawn()
	var npc_spawn_dict = get_matching_entities_values(data, mission_name, "npc_spawn", "NPCSpawns", true)
	for k in npc_spawn_dict.keys():
		k.allow_spawn = npc_spawn_dict[k]
		k.spawn()
	var prop_spawn_dict = get_matching_entities_values(data, mission_name, "prop_spawn", "PropSpawns", true)
	for k in prop_spawn_dict.keys():
		k.allow_spawn = prop_spawn_dict[k]
		k.spawn()
	var trigger_spawn_dict = get_matching_entities_values(data, mission_name, "trigger_spawn", "TriggerSpawns", true)
	for k in trigger_spawn_dict.keys():
		k.allow_spawn = trigger_spawn_dict[k]
		k.spawn()

#free
	var enemy_free_dict = get_matching_entities_values(data, mission_name, "enemy_free", "Enemies", false)
	for k in enemy_free_dict.keys():
		k.die(true)
	var npc_free_dict = get_matching_entities_values(data, mission_name, "npc_free", "NPCs", false)
	for k in npc_free_dict.keys():
		k.queue_free() #Warning: Untested
	var prop_free_dict = get_matching_entities_values(data, mission_name, "prop_free", "Props", false)
	for k in prop_free_dict.keys():
		k.queue_free() #Warning: Untested
	var trigger_free_dict = get_matching_entities_values(data, mission_name, "trigger_free", "Triggers", false)
	for k in trigger_free_dict.keys():
		k.queue_free() #Warning: Untested

#runtime_position
	var enemy_runtime_position_dict = get_matching_entities_values(data, mission_name, "enemy_runtime_position", "Enemies", false)
	for k in enemy_runtime_position_dict.keys():
		k.global_position = array_to_vector2(enemy_runtime_position_dict[k])
	var npc_runtime_position_dict = get_matching_entities_values(data, mission_name, "npc_runtime_position", "NPCs", false)
	for k in npc_runtime_position_dict.keys():
		k.global_position = array_to_vector2(npc_runtime_position_dict[k])
	var prop_runtime_position_dict = get_matching_entities_values(data, mission_name, "prop_runtime_position", "Props", false)
	for k in prop_runtime_position_dict.keys():
		k.global_position = array_to_vector2(prop_runtime_position_dict[k])
	var trigger_runtime_position_dict = get_matching_entities_values(data, mission_name, "trigger_runtime_position", "Triggers", false)
	for k in trigger_runtime_position_dict.keys():
		k.global_position = array_to_vector2(trigger_runtime_position_dict[k])

#runtime_position_offset
	var enemy_runtime_position_offset_dict = get_matching_entities_values(data, mission_name, "enemy_runtime_position_offset", "Enemies", false)
	for k in enemy_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(enemy_runtime_position_offset_dict[k])
	var npc_runtime_position_offset_dict = get_matching_entities_values(data, mission_name, "npc_runtime_position_offset", "NPCs", false)
	for k in npc_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(npc_runtime_position_offset_dict[k])
	var prop_runtime_position_offset_dict = get_matching_entities_values(data, mission_name, "prop_runtime_position_offset", "Props", false)
	for k in prop_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(prop_runtime_position_offset_dict[k])
	var trigger_runtime_position_offset_dict = get_matching_entities_values(data, mission_name, "trigger_runtime_position_offset", "Triggers", false)
	for k in trigger_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(trigger_runtime_position_offset_dict[k])

#npc_set_conversation_queue
	var npc_set_conversation_queue_dict = get_matching_entities_values(data, mission_name, "npc_set_conversation_queue", "NPCs", false)
	for k in npc_set_conversation_queue_dict.keys():
		if npc_set_conversation_queue_dict[k] is String:
			k.conversation_queue = [[npc_set_conversation_queue_dict[k], false]]
		else:
			k.conversation_queue = npc_set_conversation_queue_dict[k]
#npc_append_conversation_queue
	var npc_append_conversation_queue_dict = get_matching_entities_values(data, mission_name, "npc_append_conversation_queue", "NPCs", false)
	for k in npc_append_conversation_queue_dict.keys():
		if npc_append_conversation_queue_dict[k] is String:
			k.conversation_queue.append_array([npc_append_conversation_queue_dict[k], false])
		else:
			k.conversation_queue.append_array(npc_append_conversation_queue_dict[k])

func setup_level_via_mission(mission_name = "Main"): #on level enter
	var json = load(w.current_level.mission_level_update)
	var data = json.get_data()


#allow_spawn
	var enemy_allow_spawn_dict = get_matching_entities_values(data, mission_name, "enemy_allow_spawn", "EnemySpawns", true)
	for k in enemy_allow_spawn_dict.keys():
		k.allow_spawn = enemy_allow_spawn_dict[k]
	var npc_allow_spawn_dict = get_matching_entities_values(data, mission_name, "npc_allow_spawn", "NPCSpawns", true)
	for k in npc_allow_spawn_dict.keys():
		k.allow_spawn = npc_allow_spawn_dict[k]
	var prop_allow_spawn_dict = get_matching_entities_values(data, mission_name, "prop_allow_spawn", "PropSpawns", true)
	for k in prop_allow_spawn_dict.keys():
		k.allow_spawn = prop_allow_spawn_dict[k]
	var trigger_allow_spawn_dict = get_matching_entities_values(data, mission_name, "trigger_allow_spawn", "TriggerSpawns", true)
	for k in trigger_allow_spawn_dict.keys():
		k.allow_spawn = trigger_allow_spawn_dict[k]

#spawn_position
	var enemy_spawn_position_dict = get_matching_entities_values(data, mission_name, "enemy_spawn_position", "EnemySpawns", true)
	for k in enemy_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(enemy_spawn_position_dict[k])
	var npc_spawn_position_dict = get_matching_entities_values(data, mission_name, "npc_spawn_position", "NPCSpawns", true)
	for k in npc_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(npc_spawn_position_dict[k])
	var prop_spawn_position_dict = get_matching_entities_values(data, mission_name, "prop_spawn_position", "PropSpawns", true)
	for k in prop_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(prop_spawn_position_dict[k])
	var trigger_spawn_position_dict = get_matching_entities_values(data, mission_name, "trigger_spawn_position", "TriggerSpawns", true)
	for k in trigger_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(trigger_spawn_position_dict[k])

#spawn_position_offset
	var enemy_spawn_position_offset_dict = get_matching_entities_values(data, mission_name, "enemy_spawn_position_offset", "EnemySpawns", true)
	for k in enemy_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(enemy_spawn_position_offset_dict[k])
	var npc_spawn_position_offset_dict = get_matching_entities_values(data, mission_name, "npc_spawn_position_offset", "NPCSpawns", true)
	for k in npc_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(npc_spawn_position_offset_dict[k])
	var prop_spawn_position_offset_dict = get_matching_entities_values(data, mission_name, "prop_spawn_position_offset", "PropSpawns", true)
	for k in prop_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(prop_spawn_position_offset_dict[k])
	var trigger_spawn_position_offset_dict = get_matching_entities_values(data, mission_name, "trigger_spawn_position_offset", "TriggerSpawns", true)
	for k in trigger_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(trigger_spawn_position_offset_dict[k])

#npc_set_conversation_queue
	var npc_set_conversation_queue_dict = get_matching_entities_values(data, mission_name, "npc_set_conversation_queue", "NPCSpawns", true)
	for k in npc_set_conversation_queue_dict.keys():
		if npc_set_conversation_queue_dict[k] is String:
			k.properties["conversation_queue"][0] = [[npc_set_conversation_queue_dict[k], false]]
		else:
			k.properties["conversation_queue"][0] = npc_set_conversation_queue_dict[k]
#npc_append_conversation_queue
	var npc_append_conversation_queue_dict = get_matching_entities_values(data, mission_name, "npc_append_conversation_queue", "NPCSpawns", true)
	for k in npc_append_conversation_queue_dict.keys():
		if npc_append_conversation_queue_dict[k] is String:
			k.properties["conversation_queue"][0].append_array([npc_append_conversation_queue_dict[k], false])
		else:
			k.properties["conversation_queue"][0].append_array(npc_append_conversation_queue_dict[k])


#level_conversation_on_enter
	if data.has("level_conversation_on_enter"):
		if data["level_conversation_on_enter"].has(mission_name):
			var mission_stage: String
			if mission_name == "Main":
				mission_stage = main_mission_stage
			else:
				mission_stage = mission_name_to_mission(mission_name).current_stage
			for stage in data["level_conversation_on_enter"][mission_name]:
				if stage == mission_stage:
					w.current_level.conversation_on_enter = data["level_conversation_on_enter"][mission_name][stage]

### HELPER ###

func get_matching_entities_values(data, mission_name, data_key, group, is_spawn) -> Dictionary:
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
				var mission_stage: String
				if mission_name == "Main":
					mission_stage = main_mission_stage
				else:
					mission_stage = mission_name_to_mission(mission_name).current_stage

				if data[data_key][mission_name][id].has(mission_stage):
					out[n] = data[data_key][mission_name][id][mission_stage]
				elif data[data_key][mission_name][id].has("any"):
					out[n] = data[data_key][mission_name][id]["any"]
	return out


func array_to_vector2(array) -> Vector2:
	return Vector2(array[0], array[1])


func mission_name_to_mission(mission_name) -> SideMission:
	var out: SideMission
	for m in side_missions:
		if m.resource_path.get_file().trim_suffix(".tres") == mission_name:
			out = m
	return out
