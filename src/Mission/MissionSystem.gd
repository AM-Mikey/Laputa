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



func update_level_via_main_mission():
	var json = load(w.current_level.main_mission_level_update)

	var data = json.get_data()

	for id in data["npc_dialog_updates"]:
		for n in get_tree().get_nodes_in_group("NPCs"):
			if n.id == id:
				n.conversation = data["npc_dialog_updates"][id][main_mission_stage]

func setup_level_via_main_mission():
	var json = load(w.current_level.main_mission_level_update)
	var data = json.get_data()

	for id in data["npc_dialog_updates"]:
		for n in get_tree().get_nodes_in_group("NPCSpawns"):
			if n.properties["id"][0] == id:
				n.properties["conversation"][0] = data["npc_dialog_updates"][id][main_mission_stage]


	for id in data["enemy_allow_spawn"]:
		for e in get_tree().get_nodes_in_group("EnemySpawns"):
			if e.properties["id"][0] == id:
				e.allow_spawn = data["enemy_allow_spawn"][id][main_mission_stage]
