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
	await get_tree().create_timer(1.0).timeout

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
	dialog_box.start_printing("res://src/Dialog/TreasureHunterBossTest.json", "boss_intro_dialog", "cutscene")

	await dialog_box.dialog_finished

	await boss_health_bar_filled_anim()
	boss_battle_start()


func _on_boss_killed():
	ms.progress_main_mission.call_deferred()
	await win_animation()
	end()

func win_animation():
	var boss = get_entity_with_id("Enemies", boss_id)
	boss_hp_bar.hide_ui()
	disable_player_input()

	await boss.anim_death_finished

	#Make a Victory dialog
	am.play_music("victory")
	var dialog_box = create_dialog_box()
	dialog_box.start_printing("res://src/Dialog/TreasureHunterBossTest.json", "boss_victory", "cutscene")
	await dialog_box.dialog_finished

	var level = w.current_level
	var level_limiter = get_level_limiter()
	var level_trans_tween: Tween = transition_level_limit(level_limiter.default_limit, 1.0)

	enable_player_input()

	am.play_music(level.music)

	await level_trans_tween.finished
	return
