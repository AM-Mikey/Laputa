extends Node

class_name Cutscene

@onready var boss_health_bar_scene = preload("res://src/Cutscene/BossHealthBar.tscn")
@onready var w = get_tree().get_root().get_node("World")

var boss_health_bar = null

const DB = preload("res://src/Dialog/DialogBox.tscn")
const dialog_json = "res://src/Dialog/BossTest.json"


# Called when the node enters the scene tree for the first time.
func _ready():
	if !w.is_node_ready():
		await w.ready

	 # To "boss_test_player_to_intro_position"
	disable_player_input()
	setup()


func setup():
	ms.progress_main_mission.call_deferred()
	var player = f.pc()
	move_player_to(Vector2(592, 288))
	var new_level_limit_rect: Rect2 = Rect2(Vector2(480, 32), Vector2(992 - 480, 272))
	transition_level_limit(new_level_limit_rect, 1.2)
	if !player.end_move_to.is_connected(_on_player_reach_intro_position):
		player.end_move_to.connect(_on_player_reach_intro_position)

func end():
	queue_free()

func _end():
	pass

func _on_player_reach_intro_position():
	am.stop_music()
	ms.progress_main_mission() # To "boss_test_intro_drop"

func _process(_delta: float) -> void:
	if ms.main_mission_stage[0] == "boss_test_intro_drop":
		var golem_boss = get_entity_with_id("Enemies", "golem")
		if golem_boss and golem_boss.is_on_floor():
			_on_boss_finished_dropping()



func _on_boss_finished_dropping():
	ms.progress_main_mission() # To "boss_test_intro_drop"
	am.play_music("boss_buildup")
	var golem_boss = get_entity_with_id("Enemies", "golem")
	golem_boss.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	var dialog_box = create_dialog_box()
	dialog_box.start_printing(dialog_json, "boss_intro_dialog", "cutscene")
	await dialog_box.dialog_finished
	_on_boss_dialog_finished()


func _on_boss_dialog_finished():
	boss_health_bar = boss_health_bar_scene.instantiate()
	w.ui.add_child(boss_health_bar)
	boss_health_bar.boss = get_entity_with_id("Enemies", "golem")
	boss_health_bar.show_ui()
	await boss_health_bar.anim_bar_filled_finished
	am.pause_music(true)
	await get_tree().create_timer(1.0).timeout
	_on_boss_health_bar_animation_finsihed()


func _on_boss_health_bar_animation_finsihed():
	ms.progress_main_mission() # Start boss fight
	am.pause_music(false)
	am.play_music("boss")
	var golem_boss = get_entity_with_id("Enemies", "golem")
	golem_boss.killed.connect(_on_boss_killed)
	golem_boss.process_mode = ProcessMode.PROCESS_MODE_INHERIT
	enable_player_input()


func _on_boss_killed():
	boss_health_bar.hide_ui()
	disable_player_input()
	var boss_die_position = get_entity_with_id("Enemies", "golem").global_position
	var boss_cutscene_enemy_spawn = get_spawner_with_id("EnemySpawns", "golem_cutscene")
	boss_cutscene_enemy_spawn.allow_spawn = true
	boss_cutscene_enemy_spawn.spawn()
	await get_tree().process_frame
	#Spawn Smoke
	var boss_cutscene_enemy = get_entity_with_id("Enemies", "golem_cutscene")
	boss_cutscene_enemy.global_position = boss_die_position
	boss_cutscene_enemy.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	var smoke_scene = preload("res://src/Effect/GunSmoke.tscn")
	for i in range(0, 25):
		am.play("enemy_die", null, null)
		for j in range(0, 1 + randi() % 3):
			var smoke = smoke_scene.instantiate()
			smoke.global_position = boss_die_position + Vector2(10.0 * randf_range(-1.0, 1.0), 10.0 * randf_range(-1.0, 1.0))
			w.player_front.add_child(smoke)
		await get_tree().create_timer(0.1).timeout
		if i in [23, 24, 25]:
			if boss_cutscene_enemy:
				var explosion_scene = preload("res://src/Effect/GrenadeExplosion.tscn")
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

	var level_limiter = get_level_limiter()
	var level_trans_tween: Tween = transition_level_limit(level_limiter.default_limit, 1.0)

	ms.progress_main_mission()
	enable_player_input()
	am.play_music("train_intro")

	await level_trans_tween.finished
	end()

## UTILITY
func transition_level_limit(to_limit_rect: Rect2, time: float) -> Tween:
	var ll = get_level_limiter()
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.tween_method(set_level_limit, ll.get_level_rect(), to_limit_rect, time)
	return tween

func set_level_limit(limit_rect: Rect2):
	var ll = get_level_limiter()
	ll.global_position = limit_rect.position
	ll.size = limit_rect.size
	ll.update_blackbars()
	ll.update_layers()

func get_level_limiter():
	return w.current_level.get_node("LevelLimiter")

# Player camera
func get_player_camera() -> Camera2D:
	var player = f.pc()
	if player:
		var camera = player.get_node_or_null("PlayerCamera")
		return camera
	return null

func reset_player_camera(rect: Rect2):
	var camera = get_player_camera()
	camera.control_stop()
	camera.reset()

func move_player_to(pos: Vector2):
	var player = f.pc()
	player.move_to(pos)

func disable_player_input():
	inp.can_act = false

func enable_player_input():
	inp.can_act = true


func get_entity_with_id(group: String, id):
	return ms.get_entity_with_id(group, id)

func get_spawner_with_id(group: String, id):
	return ms.get_spawner_with_id(group, id)


## Return the dialog box
func create_dialog_box() -> Control:
	var dialog_box = DB.instantiate()
	#dialog_box.connect("dialog_finished", Callable(self, "on_dialog_finished"))
	w.dll.add_child(dialog_box)
	return dialog_box

## If [param=dialog_box] is null, the first dialog box (if existed) will be closed instead
func hide_dialog_box(dialog_bos: Control = null):
	if dialog_bos:
		dialog_bos.exit()
	else:
		if f.db(): #clear old dialog box if there is one
			f.db().exit()
