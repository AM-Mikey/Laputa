extends Node

class_name Cutscene

@onready var w = get_tree().get_root().get_node("World")

const DB = preload("res://src/Dialog/DialogBox.tscn")
const dialog_json = "res://src/Dialog/BossTest.json"


# Called when the node enters the scene tree for the first time.
func _ready():
	if !w.is_node_ready():
		await w.ready
	setup()

func setup():
	pass

func end():
	queue_free()

func _end():
	pass


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

func force_spawner_spawn(group: String, id):
	var spawner = get_spawner_with_id(group, id)
	spawner.allow_spawn = true
	spawner.spawn()
	await get_tree().process_frame
	spawner.allow_spawn = false


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
