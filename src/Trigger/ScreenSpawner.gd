extends Trigger

## Which enemy to spawn
@export var enemy_path: String = ""
## How many enemy per spawn
#@export var enemy_per_spawn: int = 1
## Spawn a new enemy after specified interval, given the spawner does not spawn more than [member=max_enemy_on_screen]
@export var spawn_interval: float = 5.0

## In 4 cardinal direction only
## The spawning enemy will be given a Dictionary {"dir": Vector2}
## The spawner will infer the direction from how the player enters the spawn zone.
@export var spawn_horizontal: bool = true
@export var spawn_vertical: bool = true
## If set to any value different front Vector2.ZERO, spawn_horizontal, spawn_vertical will be ignored and spawn direction will always set to this value.
@export var only_spawn_direction: Vector2 = Vector2.ZERO
## If spawn in horizontal directions, the spawner will only take the top and bottom edges as limit.
## Similar for vertical direction, the spawner will only take the left and right edges as limits
var spawn_area: Rect2

@onready var actors = w.current_level.get_node("Actors")
@onready var ll = w.current_level.get_node("LevelLimiter")

var enemy_speed: Vector2 = Vector2.ZERO

var player_in_trigger := false
var curr_spawn_direction := Vector2.ZERO:
	set(val):
		match curr_spawn_direction:
			Vector2.UP:
				$DespawnBoudary/Up/CollisionShape2D.set_deferred("disabled", true)
			Vector2.RIGHT:
				$DespawnBoudary/Right/CollisionShape2D.set_deferred("disabled", true)
			Vector2.DOWN:
				$DespawnBoudary/Bottom/CollisionShape2D.set_deferred("disabled", true)
			Vector2.LEFT:
				$DespawnBoudary/Left/CollisionShape2D.set_deferred("disabled", true)
		match val:
			Vector2.UP:
				$DespawnBoudary/Up/CollisionShape2D.set_deferred("disabled", false)
			Vector2.RIGHT:
				$DespawnBoudary/Right/CollisionShape2D.set_deferred("disabled", false)
			Vector2.DOWN:
				$DespawnBoudary/Bottom/CollisionShape2D.set_deferred("disabled", false)
			Vector2.LEFT:
				$DespawnBoudary/Left/CollisionShape2D.set_deferred("disabled", false)
		curr_spawn_direction = val

func _ready():
	trigger_type = "screen_spawner"
	spawn_area = Rect2( - $CollisionShape2D.shape.size / 2.0, $CollisionShape2D.shape.size)
	$SpawnTimer.wait_time = spawn_interval
	spawn_area = $SpawnArea.value

	if !(FileAccess.file_exists(enemy_path)):
		printerr("ScreenSpawner %s | _ready(): Invalid enemy_path %s" % [name, enemy_path])
		return

	var sample_enemy = load(enemy_path).instantiate()
	sample_enemy.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	actors.add_child(sample_enemy)
	enemy_speed = sample_enemy.speed

	$DespawnBoudary/Up.global_position = ll.global_position + Vector2(0.0, -100.0)
	$DespawnBoudary/Left.global_position = ll.global_position + Vector2(-100.0, 0.0)
	$DespawnBoudary/Right.global_position = ll.global_position + ll.size + Vector2(100.0, 0.0)
	$DespawnBoudary/Bottom.global_position = ll.global_position + ll.size + Vector2(0.0, 100.0)

var min_screen_size: Vector2i = Vector2i(200, 100)
var max_screen_size: Vector2i = Vector2i(3000, 2000)

var unprocessed_enemy: Array = []
var processed_enemy: Array = []

#func _physics_process(delta: float) -> void:
	#print(processed_enemy.size())

func _exit_tree() -> void:
	for en in unprocessed_enemy:
		if (is_instance_valid(en)):
			en.queue_free()
	for en in processed_enemy:
		if (is_instance_valid(en)):
			en.queue_free()


func _on_SpawnTimer_timeout() -> void:
	for en in unprocessed_enemy:
		en.queue_free()
	unprocessed_enemy = []

	var enemy_scene = load(enemy_path)

	var camera: Camera2D = get_viewport().get_camera_2d()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size / vs.resolution_scale
	var screen_position: Vector2 = camera.get_screen_center_position() - screen_size / 2.0
	var screen_rect: Rect2 = Rect2(screen_position, screen_size)
	var level_rect: Rect2 = Rect2(ll.global_position, ll.size)
	var curr_spawn_area: Rect2 = spawn_area.intersection(screen_rect)

	var enemy_distance: float = enemy_speed.x * spawn_interval
	var enemy_spread_on_ortho: int = 0
	var enemy_distance_on_ortho: float = 0.0

	# Remove all invalid processed enemy. Including dead
	var to_be_deleted_enemy: Array = processed_enemy.filter(func (ele): return  !ele or !is_instance_valid(ele) or ele.is_queued_for_deletion())
	for en in to_be_deleted_enemy:
		if is_instance_valid(en):
			en.queue_free()

	# WIP full screen spawn
	match curr_spawn_direction:
		Vector2.RIGHT, Vector2.LEFT:
			# Find the farthest spawned one on the screen. If there is no enemy or the farthest one is less than the screen edge, default to that screen edge
			var default_spawn_screen_edge_x: float = screen_position.x if curr_spawn_direction == Vector2.RIGHT else screen_position.x + screen_size.x
			var curr_x: float = default_spawn_screen_edge_x
			var valid_processed_enemy: Array = processed_enemy.filter(func (ele): return ele not in to_be_deleted_enemy)
			if valid_processed_enemy.size() > 0:
				var farthest_spawned_x: float = 0.0
				if curr_spawn_direction == Vector2.RIGHT:
					farthest_spawned_x = valid_processed_enemy.reduce(func (accum, ele): return min(ele.global_position.x, accum), 9999999999)
				else:
					farthest_spawned_x = valid_processed_enemy.reduce(func (accum, ele): return max(ele.global_position.x, accum), -9999999999)
				if (curr_spawn_direction == Vector2.RIGHT and farthest_spawned_x < default_spawn_screen_edge_x) or \
					(curr_spawn_direction == Vector2.LEFT and farthest_spawned_x > default_spawn_screen_edge_x):
					curr_x = farthest_spawned_x + enemy_distance * -curr_spawn_direction.x
			processed_enemy = valid_processed_enemy

			#region Test 1: Spawn an enemy at the edge and many more standby (disabled and invis until on screen) further out from the edge
			## Resulting in some to spawn fast or slow depending on the screen move speed
			## Fresh spawn from the edge of the screen
			#var final_x: float = curr_x + 1000.0 * -curr_spawn_direction.x
			#var enemy = enemy_scene.instantiate()
			#enemy.dir = curr_spawn_direction
			#enemy.global_position.y = randf() * screen_size.y + screen_position.y
			#enemy.global_position.x = curr_x
			#actors.add_child(enemy)
			#processed_enemy.append(enemy)
			#curr_x += enemy_distance * -curr_spawn_direction.x
#
			## Spawn aheads but will not be active until enter screen
			#while !is_equal_approx(curr_x, final_x):
				#var visible_notifier: VisibleOnScreenEnabler2D = VisibleOnScreenEnabler2D.new()
				#var enemy_ahead = enemy_scene.instantiate()
				#enemy_ahead.process_mode = PROCESS_MODE_DISABLED
				#enemy_ahead.visible = false
				#enemy_ahead.global_position.y = randf() * screen_size.y + screen_position.y
				#enemy_ahead.global_position.x = curr_x
				#enemy_ahead.dir = curr_spawn_direction
				#var enemy_ahead_boundary_rect = enemy_ahead.get_node("CollisionShape2D").shape.get_rect()
				#visible_notifier.enable_mode = VisibleOnScreenEnabler2D.ENABLE_MODE_INHERIT
				#visible_notifier.rect = enemy_ahead_boundary_rect
				#visible_notifier.show_rect = true # Later change
				#visible_notifier.screen_entered.connect(visible_notifier.queue_free)
				#visible_notifier.screen_entered.connect(unprocessed_enemy.erase.bind(enemy_ahead))
				#visible_notifier.screen_entered.connect(processed_enemy.append.bind(enemy_ahead))
#
				#enemy_ahead.add_child(visible_notifier)
				#actors.add_child(enemy_ahead)
				#unprocessed_enemy.append(enemy_ahead)
				#curr_x += enemy_distance * -curr_spawn_direction.x
			#endregion

			#region Test 2: Spawn enemies preemptively and continue spawning from the farthest one
			enemy_distance_on_ortho = screen_size.y
			var average_one_wave_spawn_on_ortho: int = ceil(spawn_area.size.y / enemy_distance_on_ortho)
			var to_spawn: int = 0
			var enemy_beyond_screen_edge: int = 0
			if (curr_spawn_direction == Vector2.RIGHT):
				enemy_beyond_screen_edge = processed_enemy.reduce(func (accum, ele): return accum + 1 if ele.global_position.x < default_spawn_screen_edge_x else accum, 0)
			else:
				enemy_beyond_screen_edge = processed_enemy.reduce(func (accum, ele): return accum + 1 if ele.global_position.x > default_spawn_screen_edge_x else accum, 0)
			if (enemy_beyond_screen_edge < 3 * average_one_wave_spawn_on_ortho):
				to_spawn = 3
			elif (enemy_beyond_screen_edge < 5 * average_one_wave_spawn_on_ortho):
				to_spawn = 2
			elif (enemy_beyond_screen_edge < 10 * average_one_wave_spawn_on_ortho):
				to_spawn = 1
			else:
				to_spawn = 0

			var near_screen_y: float = curr_spawn_area.position.y + curr_spawn_area.size.y * randf()
			var enemy_spread_on_ortho_min_section: int = ceil((spawn_area.position.y - near_screen_y) / enemy_distance_on_ortho)
			var enemy_spread_on_ortho_max_section: int = floor((spawn_area.position.y + spawn_area.size.y - near_screen_y) / enemy_distance_on_ortho)
			#print(curr_spawn_area, " ", screen_rect, " ", spawn_area)

			for i in range(0, to_spawn):
				for j in range(enemy_spread_on_ortho_min_section, enemy_spread_on_ortho_max_section + 1):
					var curr_y: float = near_screen_y + j * enemy_distance_on_ortho * (0.9 + 0.2 * randf())
					if (spawn_area.position.y > curr_y or spawn_area.position.y + spawn_area.size.y < curr_y):
						continue
					var enemy = enemy_scene.instantiate()
					enemy.global_position.y = curr_y
					enemy.global_position.x = curr_x + (-0.2 + randf() * 0.1) * enemy_distance
					enemy.dir = curr_spawn_direction

					actors.add_child(enemy)
					processed_enemy.append(enemy)
				curr_x += enemy_distance * -curr_spawn_direction.x
				if (curr_x < level_rect.position.x or curr_x > level_rect.position.x + level_rect.size.x):
					break

			#region

### SIGNAL ###
func _on_body_entered(body: Node2D):
	var player_direction: Vector2 = $CollisionShape2D.global_position.direction_to(body.global_position)
	var player_direction_angle := player_direction.angle()

	for boundary in $DespawnBoudary.get_children():
		boundary.get_node("CollisionShape2D").set_deferred("disabled", true)

	var detection_rect: Rect2 = Rect2($CollisionShape2D.global_position - $CollisionShape2D.shape.size / 2.0 , $CollisionShape2D.shape.size)
	var player_x_percent: float = (body.global_position.x - detection_rect.position.x) / detection_rect.size.x
	var player_y_percent: float = (body.global_position.y - detection_rect.position.y) / detection_rect.size.y

	if (only_spawn_direction == Vector2.ZERO): #WIP: Improve this to a rectangle, this is only suited for sawure
		if (spawn_horizontal):
			if (player_x_percent < 0.5):
				curr_spawn_direction = Vector2.LEFT
			else:
				curr_spawn_direction = Vector2.RIGHT
		elif (spawn_vertical):
			if (player_y_percent < 0.5):
				curr_spawn_direction = Vector2.UP
			else:
				curr_spawn_direction = Vector2.DOWN

	elif (only_spawn_direction):
		curr_spawn_direction = only_spawn_direction

	player_in_trigger = true
	$SpawnTimer.start()

func _on_body_exited(_body: Node2D):
	if (is_queued_for_deletion()):
		return

	player_in_trigger = false
	for en in unprocessed_enemy:
		en.queue_free()
	unprocessed_enemy = []

	var camera: Camera2D = get_viewport().get_camera_2d()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size / vs.resolution_scale
	var screen_position: Vector2 = camera.get_screen_center_position() - screen_size / 2.0
	var screen_edge_x: float = screen_position.x if curr_spawn_direction == Vector2.RIGHT else screen_position.x + screen_size.x
	for en in processed_enemy:
		if (curr_spawn_direction == Vector2.RIGHT and en.global_position.x < screen_edge_x) or \
			(curr_spawn_direction == Vector2.LEFT and en.global_position.x > screen_edge_x):
			en.queue_free()
	processed_enemy = processed_enemy.filter(func (ele): return !ele and !ele.dead and !ele.is_queued_for_deletion())
	$SpawnTimer.stop()

func _on_despawn_boundary_body_entered(actor: Enemy) -> void:
	if (actor in processed_enemy):
		actor.queue_free()
		processed_enemy.erase(actor)
