extends Cutscene

class_name BossCutscene

const BOSS_HEALTH_BAR = preload("res://src/UI/BossHealthBar.tscn")

var boss_id = ""
var boss_arena_rect: Rect2 = Rect2()

var boss_hp_bar

var boss_music: String = "boss"

## Override this to implement custom behaviour when the boss die
func _on_boss_killed():
	pass

## Override this to implement custom behaviour when the player die
func _on_player_killed():
	queue_free()

## UTILITY
func boss_health_bar_filled_anim():
	#var boss = get_entity_with_id("Enemies", boss_id)
	var boss = get_entity_with_id("Enemies", boss_id)
	if boss is Boss:
		boss_hp_bar = boss.hp_bar
	elif boss:
		boss_hp_bar = BOSS_HEALTH_BAR.instantiate()
		boss_hp_bar.boss = boss
		w.ui.add_child(boss_hp_bar)
	else:
		push_error("Cannot find boss with id: ", boss_id)
		return
	boss_hp_bar.show_ui()

	await boss_hp_bar.anim_bar_filled_finished
	am.pause_music(true)
	await get_tree().create_timer(1.0).timeout
	return

func boss_battle_start():
	am.play_music(boss_music)
	var player = f.pc()
	player.killed.connect(_on_player_killed)
	pan_camera_to(get_player_camera(), player.global_position, 0.2)
	var boss = get_entity_with_id("Enemies", boss_id)
	boss.killed.connect(_on_boss_killed)
	boss.process_mode = ProcessMode.PROCESS_MODE_INHERIT
	if boss.has_method("start_ai"):
		boss.start_ai()
	enable_player_input()

func win_animation():
	var boss = get_entity_with_id("Enemies", boss_id)
	boss_hp_bar.hide_ui()
	disable_player_input()

	await boss.anim_death_finished

	#Make a Victory dialog
	am.play_music("victory")
	var dialog_box = create_dialog_box()
	dialog_box.start_printing("res://src/Dialog/BossTest.json", "boss_victory", "cutscene")
	await dialog_box.dialog_finished

	var level = w.current_level
	var level_limiter = get_level_limiter()
	var level_trans_tween: Tween = transition_level_limit(level_limiter.default_limit, 1.0)

	enable_player_input()

	am.play_music(level.music)

	await level_trans_tween.finished
	return
