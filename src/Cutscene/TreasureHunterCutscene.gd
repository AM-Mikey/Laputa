extends BossCutscene

func start():
	disable_player_input()
	var player_move_to_hotspot = get_waypoint_with_id("WaypointGlobals", "cutscene_player_intro_pos")
	var camera_move_to_hotspot = get_waypoint_with_id("WaypointGlobals", "cutscene_camera_to_pos")
	var player = f.pc()

	move_player_to(player_move_to_hotspot.global_position)
	transition_level_limit(boss_arena_rect, 1.2)
	pan_camera_to(get_player_camera(), camera_move_to_hotspot.global_position, 0.5)

	await player.end_move_to

	# Boss approach
	await force_spawner_spawn("BossSpawns", boss_id)
	am.stop_music()
	var boss = get_entity_with_id("Bosses", boss_id)
	var boss_move_to_hotspot = get_waypoint_with_id("WaypointGlobals", "cutscene_boss_intro_pos")
	boss.move_to(boss_move_to_hotspot.global_position)

	await boss.end_move_to

	# Boss talking
	ms.progress_main_mission()
	am.play_music("boss_buildup")
	var dialog_box = create_dialog_box()
	dialog_box.start_printing(dialog_json, "boss_intro_dialog", "cutscene")

	await dialog_box.dialog_finished

	await boss_health_bar_filled_anim()
	boss_battle_start()


func _on_boss_killed():
	ms.progress_main_mission.call_deferred()
	await win_animation()
	end()
