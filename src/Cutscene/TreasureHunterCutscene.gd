extends BossCutscene

var player_audio_listener = null

func start():
	disable_player_input()
	var player_move_to_hotspot = get_waypoint_with_id("WaypointGlobals", "cutscene_player_intro_pos")
	var camera_move_to_hotspot = get_waypoint_with_id("WaypointGlobals", "cutscene_camera_to_pos")
	var player = f.pc()

	create_player_audio_listener()

	move_player_to(player_move_to_hotspot.global_position)
	transition_level_limit(boss_arena_rect, 1.2)

	cutscene_camera.limit_right = boss_arena_rect.end.x
	cutscene_camera.make_current()
	pan_camera_to(cutscene_camera, camera_move_to_hotspot.global_position, 0.5)

	await player.end_move_to
	await get_tree().create_timer(0.5).timeout

	# Boss approach
	am.stop_music()
	var boss = get_entity_with_id("Bosses", boss_id)
	var boss_move_to_hotspot = get_waypoint_with_id("WaypointGlobals", "cutscene_boss_intro_pos")
	boss.move_to(boss_move_to_hotspot.global_position, 60.0)

	await boss.end_move_to

	# Boss talking
	var original_propeller_volume = boss.get_node("PropellerLoop").volume_db
	boss.get_node("PropellerLoop").volume_db = 5.0
	ms.progress_main_mission()
	am.play_music("boss_buildup")
	var dialog_box = create_dialog_box()
	dialog_box.start_printing("res://src/Dialog/TreasureHunterBossTest.json", "boss_intro_dialog", "cutscene")
	await dialog_box.dialog_finished

	boss.get_node("PropellerLoop").volume_db = original_propeller_volume
	await boss_health_bar_filled_anim()

	boss_battle_start()
	remove_player_audio_listener()


func _on_boss_killed():
	ms.progress_main_mission.call_deferred()
	win_animation()

func win_animation():
	var boss = get_entity_with_id("Enemies", boss_id)
	boss_hp_bar.hide_ui()
	disable_player_input()

	await boss.anim_death_finished
	create_player_audio_listener()

	## Move to the outtro position
	var out_waypoint = get_waypoint_with_id("WaypointGlobals", "cutscene_boss_intro_pos")
	boss.move_to(out_waypoint.global_position, 60.0)
	boss.look_dir.x = signf(f.pc().global_position.x - boss.global_position.x)
	if boss.look_dir.x == 0.0:
		boss.look_dir.x = -1.0
	await boss.end_move_to
	boss.face_player()

	## Boss Final word
	var original_propeller_volume = boss.get_node("PropellerLoop").volume_db
	boss.get_node("PropellerLoop").volume_db = 5.0
	var dialog_box = create_dialog_box()
	dialog_box.start_printing("res://src/Dialog/TreasureHunterBossTest.json", "boss_out_dialog", "cutscene")
	await dialog_box.dialog_finished

	## Boss fly away
	boss.get_node("PropellerLoop").volume_db = original_propeller_volume
	var out_cutscene_waypoint = get_waypoint_with_id("WaypointGlobals", "cutscene_boss_get_out")
	boss.move_to(out_cutscene_waypoint.global_position, 60.0)
	await boss.end_move_to

	#Make a Victory dialog
	boss.queue_free()
	remove_player_audio_listener()
	am.play_music("victory")
	dialog_box = create_dialog_box()
	dialog_box.start_printing("res://src/Dialog/TreasureHunterBossTest.json", "boss_victory", "cutscene")
	await dialog_box.dialog_finished

	var level = w.current_level
	var level_limiter = get_level_limiter()
	var level_trans_tween: Tween = transition_level_limit(level_limiter.default_limit, 1.0)

	enable_player_input()

	am.play_music(level.music)

	await level_trans_tween.finished
	end()

func create_player_audio_listener() -> void:
	var player = f.pc()

	player_audio_listener = AudioListener2D.new()
	player_audio_listener.global_position = player.global_position
	player_audio_listener.make_current()
	add_child(player_audio_listener)

func remove_player_audio_listener() -> void:
	if player_audio_listener:
		player_audio_listener.queue_free()
		player_audio_listener = null
