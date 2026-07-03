extends Prop

const ICON = preload("res://assets/Icon/PropIcon.png")

@export var launch_force: Vector2 = Vector2.ZERO
## If true, spawn enemy regardless the player in detection zone
@export var always_active: bool = false
## The grace period after the player just entered the detection zone
@export var spawn_start_timer: float = 1.0
@export var spawn_interval: float = 1.0
@export var spawn_limit: int = -1
var spawn_count: int = 0
var spawned_actor: Array = []

@onready var actors = w.current_level.get_node("Actors")

var sample_actor = null
var sample_enemy_og_process_mode = ProcessMode.PROCESS_MODE_INHERIT
var sample_enemy_og_visible = true

func setup():
	if (always_active):
		$PlayerDetector/CollisionShape2D.shape.size = Vector2.ZERO
		$PlayerDetector.monitoring = false
	else:
		$PlayerDetector/CollisionShape2D.shape.size = $VURect.value.size
		$PlayerDetector/CollisionShape2D.position = $VURect.value.position + $VURect.value.size / 2.0
		$PlayerDetector.monitoring = true
	$SpawnTimer.wait_time = spawn_interval
	$StartTimer.wait_time = spawn_start_timer

	sample_actor = $VUActor.spawn()

	if !sample_actor:
		printerr("SpawnHole %s | _setup(): Invalid actor's file path %s" % [name, $VUActor.enemy_path])
		w.emit_signal("finished_spawn_entities_step")
		return

	sample_enemy_og_process_mode = sample_actor.process_mode
	sample_enemy_og_visible = sample_actor.visible
	sample_actor.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	sample_actor.visible = false
	sample_actor.global_position = Vector2(-1000000000, -1000000000)

	w.emit_signal("finished_spawn_entities_step")

	if (always_active):
		$StartTimer.start()

func _exit_tree() -> void:
	for enemy in spawned_actor:
		if (is_instance_valid(enemy)):
			enemy.queue_free()
	if (sample_actor):
		sample_actor.queue_free()

### UTILITY
func spawn_actor() -> Node:
	if (!sample_actor):
		printerr("SpawnHole %s: Cannot find the sample enemy!" % [name])
		return null
	var res: Node = sample_actor.duplicate()
	res.name = name # Marking name for debug
	res.visible = sample_enemy_og_visible
	res.process_mode = sample_enemy_og_process_mode
	spawned_actor.append(res)
	spawn_count += 1
	return res

## SIGNAL
func _on_SpawnTimer_timeout() -> void:
	if (spawn_limit != -1 and spawn_count >= spawn_limit):
		$StartTimer.stop()
		$SpawnTimer.stop()
		return
	var new_actor = spawn_actor()
	if !spawned_actor:
		return

	new_actor.velocity = launch_force
	new_actor.global_position = $CollisionShape2D.global_position
	actors.add_child(new_actor)

func _on_StartTimer_timeout() -> void:
	$SpawnTimer.start()

func _on_PlayerDetector_body_entered(_body: Node2D) -> void:
	$StartTimer.start()

func _on_PlayerDetector_body_exited(_body: Node2D) -> void:
	$SpawnTimer.stop()
	$StartTimer.stop()
