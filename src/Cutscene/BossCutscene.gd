extends Cutscene

class_name BossCutscene

@onready var boss_id = "golem"
@onready var boss_health_bar_scene = preload("res://src/Cutscene/BossHealthBar.tscn")
var boss_health_bar = null
var boss_arena: Rect2 = Rect2()
var boss_music: String = "boss"



func _on_boss_killed():
	pass

func _on_player_killed():
	queue_free()

## UTILITY
func boss_health_bar_filled_anim():
	boss_health_bar = boss_health_bar_scene.instantiate()
	w.ui.add_child(boss_health_bar)
	boss_health_bar.boss = get_entity_with_id("Enemies", boss_id)
	boss_health_bar.show_ui()
	tree_exiting.connect(boss_health_bar.queue_free)
	await boss_health_bar.anim_bar_filled_finished
	am.pause_music(true)
	await get_tree().create_timer(1.0).timeout
	return

func boss_battle_start():
	#ms.progress_main_mission() # Start boss fight
	am.play_music(boss_music)
	var player = f.pc()
	pan_camera_to(get_player_camera(), player.global_position, 0.2)
	var golem_boss = get_entity_with_id("Enemies", boss_id)
	golem_boss.killed.connect(_on_boss_killed)
	golem_boss.process_mode = ProcessMode.PROCESS_MODE_INHERIT
	player.killed.connect(_on_player_killed)
	enable_player_input()

func boss_die_anim():
	boss_health_bar.hide_ui()
	disable_player_input()

	var boss_die_position = get_entity_with_id("Enemies", boss_id).global_position
	var boss_cutscene_enemy_spawn = get_spawner_with_id("EnemySpawns", boss_id)
	boss_cutscene_enemy_spawn.global_position = boss_die_position
	await get_tree().process_frame
	await force_spawner_spawn("EnemySpawns", boss_id)

	#Spawn Smoke
	var boss_cutscene_enemy = get_entity_with_id("Enemies", boss_id)
	boss_cutscene_enemy.global_position = boss_die_position
	boss_cutscene_enemy.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	var smoke_scene = preload("res://src/Effect/GunSmoke.tscn")
	var explosion_scene = preload("res://src/Effect/GrenadeExplosion.tscn")
	for i in range(0, 25):
		am.play("enemy_die", null, null)
		for j in range(0, 1 + randi() % 3):
			var smoke = smoke_scene.instantiate()
			smoke.global_position = boss_die_position + Vector2(20.0 * randf_range(-1.0, 1.0), 10.0 * randf_range(-1.0, 1.0))
			w.player_front.add_child(smoke)
		await get_tree().create_timer(0.1).timeout
		if i in [23, 24, 25]:
			if boss_cutscene_enemy:
				var explosion = explosion_scene.instantiate()
				explosion.size = "Large"
				explosion.global_position = boss_die_position
				w.player_front.add_child(explosion)
				boss_cutscene_enemy.queue_free()
				am.play("boss_die")
	await get_tree().create_timer(1.0).timeout

	#Make a Victory dialog
	am.play_music("victory")
	var dialog_box = create_dialog_box()
	dialog_box.start_printing(dialog_json, "boss_victory", "cutscene")
	await dialog_box.dialog_finished

	var level = w.current_level
	var level_limiter = get_level_limiter()
	var level_trans_tween: Tween = transition_level_limit(level_limiter.default_limit, 1.0)

	enable_player_input()

	am.play_music(level.music)

	await level_trans_tween.finished
	return
