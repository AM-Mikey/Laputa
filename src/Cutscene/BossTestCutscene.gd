extends BossCutscene

func setup():
	boss_id = "golem"
	boss_arena = Rect2(Vector2(480, 32), Vector2(512, 272))

	disable_player_input()
	var player = f.pc()
	move_player_to(Vector2(592, 288))
	transition_level_limit(boss_arena, 1.2)
	pan_camera_to(get_player_camera(), Vector2(740, 188), 0.5)
	if !player.end_move_to.is_connected(_on_player_reach_intro_position):
		player.end_move_to.connect(_on_player_reach_intro_position)


func _on_player_reach_intro_position():
	am.stop_music()
	ms.progress_main_mission() # To "boss_test_intro_drop"


func _process(_delta: float) -> void:
	if ms.main_mission_stage[0] == "boss_test_intro_drop":
		var golem_boss = get_entity_with_id("Enemies", boss_id)
		if golem_boss and golem_boss.is_on_floor():
			_on_boss_finished_dropping()



func _on_boss_finished_dropping():
	ms.progress_main_mission() # To "boss_test_intro_drop"
	am.play_music("boss_buildup")
	var golem_boss = get_entity_with_id("Enemies", boss_id)
	golem_boss.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	var dialog_box = create_dialog_box()
	dialog_box.start_printing(dialog_json, "boss_intro_dialog", "cutscene")
	await dialog_box.dialog_finished
	_on_boss_dialog_finished()


func _on_boss_dialog_finished():
	await boss_health_bar_filled_anim()
	_on_boss_health_bar_animation_finsihed()

func _on_boss_health_bar_animation_finsihed():
	boss_battle_start()

func _on_boss_killed():
	ms.progress_main_mission.call_deferred()
	await boss_die_anim()
	end()
