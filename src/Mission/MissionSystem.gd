extends Node

const MAIN_MISSION_LIST = [
	"talk_npc_a",
	"talk_npc_b",
	"talk_npc_c",
	"talk_npc_d",
	"celebrate",
]

var main_mission_stage: String = MAIN_MISSION_LIST.front()

@onready var w = get_tree().get_root().get_node("World")

func progress_main_mission():
	var current_index = MAIN_MISSION_LIST.find(main_mission_stage)
	main_mission_stage = MAIN_MISSION_LIST[current_index + 1]
	update_level_via_main_mission()

func seek_main_mission(seek_value):
	main_mission_stage = seek_value
	update_level_via_main_mission()



func update_level_via_main_mission(): #while already in level
	var json = load(w.current_level.main_mission_level_update)
	var data = json.get_data()

#spawn
	var enemy_spawn_dict = get_matching_entities_values(data, "enemy_spawn", "EnemySpawns", true)
	for k in enemy_spawn_dict.keys():
		k.allow_spawn = enemy_spawn_dict[k]
		k.spawn()
	var npc_spawn_dict = get_matching_entities_values(data, "npc_spawn", "NPCSpawns", true)
	for k in npc_spawn_dict.keys():
		k.allow_spawn = npc_spawn_dict[k]
		k.spawn()
	var prop_spawn_dict = get_matching_entities_values(data, "prop_spawn", "PropSpawns", true)
	for k in prop_spawn_dict.keys():
		k.allow_spawn = prop_spawn_dict[k]
		k.spawn()
	var trigger_spawn_dict = get_matching_entities_values(data, "trigger_spawn", "TriggerSpawns", true)
	for k in trigger_spawn_dict.keys():
		k.allow_spawn = trigger_spawn_dict[k]
		k.spawn()

#free
	var enemy_free_dict = get_matching_entities_values(data, "enemy_free", "Enemies", false)
	for k in enemy_free_dict.keys():
		k.die(true)
	var npc_free_dict = get_matching_entities_values(data, "npc_free", "NPCs", false)
	for k in npc_free_dict.keys():
		k.queue_free() #Warning: Untested
	var prop_free_dict = get_matching_entities_values(data, "prop_free", "Props", false)
	for k in prop_free_dict.keys():
		k.queue_free() #Warning: Untested
	var trigger_free_dict = get_matching_entities_values(data, "trigger_free", "Triggers", false)
	for k in trigger_free_dict.keys():
		k.queue_free() #Warning: Untested

#runtime_position
	var enemy_runtime_position_dict = get_matching_entities_values(data, "enemy_runtime_position", "Enemies", false)
	for k in enemy_runtime_position_dict.keys():
		k.global_position = array_to_vector2(enemy_runtime_position_dict[k])
	var npc_runtime_position_dict = get_matching_entities_values(data, "npc_runtime_position", "NPCs", false)
	for k in npc_runtime_position_dict.keys():
		k.global_position = array_to_vector2(npc_runtime_position_dict[k])
	var prop_runtime_position_dict = get_matching_entities_values(data, "prop_runtime_position", "Props", false)
	for k in prop_runtime_position_dict.keys():
		k.global_position = array_to_vector2(prop_runtime_position_dict[k])
	var trigger_runtime_position_dict = get_matching_entities_values(data, "trigger_runtime_position", "Triggers", false)
	for k in trigger_runtime_position_dict.keys():
		k.global_position = array_to_vector2(trigger_runtime_position_dict[k])

#runtime_position_offset
	var enemy_runtime_position_offset_dict = get_matching_entities_values(data, "enemy_runtime_position_offset", "Enemies", false)
	for k in enemy_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(enemy_runtime_position_offset_dict[k])
	var npc_runtime_position_offset_dict = get_matching_entities_values(data, "npc_runtime_position_offset", "NPCs", false)
	for k in npc_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(npc_runtime_position_offset_dict[k])
	var prop_runtime_position_offset_dict = get_matching_entities_values(data, "prop_runtime_position_offset", "Props", false)
	for k in prop_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(prop_runtime_position_offset_dict[k])
	var trigger_runtime_position_offset_dict = get_matching_entities_values(data, "trigger_runtime_position_offset", "Triggers", false)
	for k in trigger_runtime_position_offset_dict.keys():
		k.global_position += array_to_vector2(trigger_runtime_position_offset_dict[k])

#npc_dialog_updates
	for id in data["npc_dialog_updates"]:
		for n in get_tree().get_nodes_in_group("NPCs"):
			if n.id == id:
				n.conversation = data["npc_dialog_updates"][id][main_mission_stage]

func setup_level_via_main_mission(): #on level enter
	var json = load(w.current_level.main_mission_level_update)
	var data = json.get_data()



#allow_spawn
	var enemy_allow_spawn_dict = get_matching_entities_values(data, "enemy_allow_spawn", "EnemySpawns", true)
	for k in enemy_allow_spawn_dict.keys():
		k.allow_spawn = enemy_allow_spawn_dict[k]
	var npc_allow_spawn_dict = get_matching_entities_values(data, "npc_allow_spawn", "NPCSpawns", true)
	for k in npc_allow_spawn_dict.keys():
		k.allow_spawn = npc_allow_spawn_dict[k]
	var prop_allow_spawn_dict = get_matching_entities_values(data, "prop_allow_spawn", "PropSpawns", true)
	for k in prop_allow_spawn_dict.keys():
		k.allow_spawn = prop_allow_spawn_dict[k]
	var trigger_allow_spawn_dict = get_matching_entities_values(data, "trigger_allow_spawn", "TriggerSpawns", true)
	for k in trigger_allow_spawn_dict.keys():
		k.allow_spawn = trigger_allow_spawn_dict[k]

#spawn_position
	var enemy_spawn_position_dict = get_matching_entities_values(data, "enemy_spawn_position", "EnemySpawns", true)
	for k in enemy_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(enemy_spawn_position_dict[k])
	var npc_spawn_position_dict = get_matching_entities_values(data, "npc_spawn_position", "NPCSpawns", true)
	for k in npc_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(npc_spawn_position_dict[k])
	var prop_spawn_position_dict = get_matching_entities_values(data, "prop_spawn_position", "PropSpawns", true)
	for k in prop_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(prop_spawn_position_dict[k])
	var trigger_spawn_position_dict = get_matching_entities_values(data, "trigger_spawn_position", "TriggerSpawns", true)
	for k in trigger_spawn_position_dict.keys():
		k.allow_spawn = array_to_vector2(trigger_spawn_position_dict[k])

#spawn_position_offset
	var enemy_spawn_position_offset_dict = get_matching_entities_values(data, "enemy_spawn_position_offset", "EnemySpawns", true)
	for k in enemy_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(enemy_spawn_position_offset_dict[k])
	var npc_spawn_position_offset_dict = get_matching_entities_values(data, "npc_spawn_position_offset", "NPCSpawns", true)
	for k in npc_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(npc_spawn_position_offset_dict[k])
	var prop_spawn_position_offset_dict = get_matching_entities_values(data, "prop_spawn_position_offset", "PropSpawns", true)
	for k in prop_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(prop_spawn_position_offset_dict[k])
	var trigger_spawn_position_offset_dict = get_matching_entities_values(data, "trigger_spawn_position_offset", "TriggerSpawns", true)
	for k in trigger_spawn_position_offset_dict.keys():
		k.allow_spawn += array_to_vector2(trigger_spawn_position_offset_dict[k])

#npc_dialog_updates
	for id in data["npc_dialog_updates"]:
		for n in get_tree().get_nodes_in_group("NPCSpawns"):
			if n.properties["id"][0] == id:
				n.properties["conversation"][0] = data["npc_dialog_updates"][id][main_mission_stage]



func get_matching_entities_values(data, data_key, group, is_spawn) -> Dictionary:
	var out = {} #node, value
	if data.has(data_key):
		for id in data[data_key]:
			for n in get_tree().get_nodes_in_group(group):
				var correct_id = false
				if is_spawn:
					if n.properties["id"][0] == id: correct_id = true
				else:
					if n.id == id: correct_id = true
				if correct_id:
					if data[data_key][id].has(main_mission_stage):
						out[n] = data[data_key][id][main_mission_stage]
					elif data[data_key][id].has("any"):
						out[n] = data[data_key][id]["any"]
	return out

func array_to_vector2(array) -> Vector2:
	return Vector2(array[0], array[1])
