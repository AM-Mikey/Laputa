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
@export var spawn_on_opposite_screen_edge: bool = true
## If set to any value different front Vector2.ZERO, spawn_horizontal, spawn_vertical will be ignored and spawn direction will always set to this value.
@export var only_spawn_direction: Vector2 = Vector2.ZERO
## If spawn in horizontal directions, the spawner will only take the top and bottom edges as limits.
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
	spawn_area = Rect2(-$CollisionShape2D.shape.size / 2.0, $CollisionShape2D.shape.size)
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
	var to_be_deleted_enemy: Array = processed_enemy.filter(func (ele): return !ele or !is_instance_valid(ele) or ele.is_queued_for_deletion())
	for en in to_be_deleted_enemy:
		if is_instance_valid(en):
			en.queue_free()

	# Find the farthest spawned one on the screen. If there is no enemy or the farthest one is less than the screen edge, default to that screen edge
	var default_spawn_screen_edge: float = get_screen_edge_position()
	var curr_pos: float = default_spawn_screen_edge
	var valid_processed_enemy: Array = processed_enemy.filter(func (ele): return ele not in to_be_deleted_enemy)
	if valid_processed_enemy.size() > 0:
		match curr_spawn_direction:
			Vector2.LEFT, Vector2.RIGHT:
				var farthest_spawned_x: float = 0.0
				if (curr_spawn_direction == Vector2.LEFT):
					farthest_spawned_x = valid_processed_enemy.reduce(func (accum, ele): return max(ele.global_position.x, accum), -9999999999)
				else:
					farthest_spawned_x = valid_processed_enemy.reduce(func (accum, ele): return min(ele.global_position.x, accum), 9999999999)
				if (curr_spawn_direction == Vector2.RIGHT and farthest_spawned_x < default_spawn_screen_edge) or \
				(curr_spawn_direction == Vector2.LEFT and farthest_spawned_x > default_spawn_screen_edge):
					curr_pos = farthest_spawned_x + enemy_distance * -curr_spawn_direction.x
			Vector2.UP, Vector2.DOWN:
				var farthest_spawned_y: float = 0.0
				if (curr_spawn_direction == Vector2.UP):
					farthest_spawned_y = valid_processed_enemy.reduce(func (accum, ele): return max(ele.global_position.y, accum), -9999999999)
				else:
					farthest_spawned_y = valid_processed_enemy.reduce(func (accum, ele): return min(ele.global_position.y, accum), 9999999999)
				if (curr_spawn_direction == Vector2.UP and farthest_spawned_y > default_spawn_screen_edge) or \
				(curr_spawn_direction == Vector2.DOWN and farthest_spawned_y < default_spawn_screen_edge):
					curr_pos = farthest_spawned_y + enemy_distance * -curr_spawn_direction.y

	processed_enemy = valid_processed_enemy

	#region Test 1: Spawn an enemy at the edge and many more standby (disabled and invis until on screen) further out from the edge
	## Resulting in some to spawn fast or slow depending on the screen move speed
	## Fresh spawn from the edge of the screen
	#var final_x: float = curr_pos + 1000.0 * -curr_spawn_direction.x
	#var enemy = enemy_scene.instantiate()
	#enemy.dir = curr_spawn_direction
	#enemy.global_position.y = randf() * screen_size.y + screen_position.y
	#enemy.global_position.x = curr_pos
	#actors.add_child(enemy)
	#processed_enemy.append(enemy)
	#curr_pos += enemy_distance * -curr_spawn_direction.x
#
	## Spawn aheads but will not be active until enter screen
	#while !is_equal_approx(curr_pos, final_x):
		#var visible_notifier: VisibleOnScreenEnabler2D = VisibleOnScreenEnabler2D.new()
		#var enemy_ahead = enemy_scene.instantiate()
		#enemy_ahead.process_mode = PROCESS_MODE_DISABLED
		#enemy_ahead.visible = false
		#enemy_ahead.global_position.y = randf() * screen_size.y + screen_position.y
		#enemy_ahead.global_position.x = curr_pos
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
		#curr_pos += enemy_distance * -curr_spawn_direction.x
	#endregion

	#region Test 2: Spawn enemies preemptively and continue spawning from the farthest one
	enemy_distance_on_ortho = screen_size.y if curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT] else screen_size.x
	var average_one_wave_spawn_on_ortho: int = ceil(spawn_area.size.y / enemy_distance_on_ortho)
	var to_spawn: int = 0
	var enemy_beyond_screen_edge: int = 0
	match curr_spawn_direction:
		Vector2.RIGHT:
			enemy_beyond_screen_edge = processed_enemy.reduce(func (accum, ele): return accum + 1 if ele.global_position.x < default_spawn_screen_edge else accum, 0)
		Vector2.LEFT:
			enemy_beyond_screen_edge = processed_enemy.reduce(func (accum, ele): return accum + 1 if ele.global_position.x > default_spawn_screen_edge else accum, 0)
		Vector2.UP:
			enemy_beyond_screen_edge = processed_enemy.reduce(func (accum, ele): return accum + 1 if ele.global_position.y < default_spawn_screen_edge else accum, 0)
		Vector2.DOWN:
			enemy_beyond_screen_edge = processed_enemy.reduce(func (accum, ele): return accum + 1 if ele.global_position.y > default_spawn_screen_edge else accum, 0)

	if (enemy_beyond_screen_edge < 3 * average_one_wave_spawn_on_ortho):
		to_spawn = 3
	elif (enemy_beyond_screen_edge < 5 * average_one_wave_spawn_on_ortho):
		to_spawn = 2
	elif (enemy_beyond_screen_edge < 10 * average_one_wave_spawn_on_ortho):
		to_spawn = 1
	else:
		to_spawn = 0

	var curr_spawn_area_ortho_position = curr_spawn_area.position.y if curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT] else curr_spawn_area.position.x
	var curr_spawn_area_ortho_size = curr_spawn_area.size.y if curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT] else curr_spawn_area.size.x
	var spawn_area_ortho_position = spawn_area.position.y if curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT] else spawn_area.position.x
	var spawn_area_ortho_size = spawn_area.size.y if curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT] else spawn_area.size.x

	var near_screen_ortho: float = curr_spawn_area_ortho_position + curr_spawn_area_ortho_size * randf()
	var enemy_spread_on_ortho_min_section: int = ceil((spawn_area_ortho_position - near_screen_ortho) / enemy_distance_on_ortho)
	var enemy_spread_on_ortho_max_section: int = floor((spawn_area_ortho_position + spawn_area_ortho_size - near_screen_ortho) / enemy_distance_on_ortho)

	for i in range(0, to_spawn):
		for j in range(enemy_spread_on_ortho_min_section, enemy_spread_on_ortho_max_section + 1):
			var curr_ortho_pos: float = near_screen_ortho + (j - 0.2 + 0.4 * randf()) * enemy_distance_on_ortho
			if (spawn_area_ortho_position > curr_ortho_pos or spawn_area_ortho_position + spawn_area_ortho_size < curr_ortho_pos):
				continue
			var enemy = enemy_scene.instantiate()
			if (curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT]):
				enemy.global_position.y = curr_ortho_pos
				enemy.global_position.x = curr_pos + (-0.2 + randf() * 0.1) * enemy_distance
			else:
				enemy.global_position.x = curr_ortho_pos
				enemy.global_position.y = curr_pos + (-0.2 + randf() * 0.1) * enemy_distance
			enemy.dir = curr_spawn_direction

			actors.add_child(enemy)
			processed_enemy.append(enemy)
		if (curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT]):
			curr_pos += enemy_distance * -curr_spawn_direction.x
			if (curr_pos < level_rect.position.x or curr_pos > level_rect.position.x + level_rect.size.x):
				break
		else:
			curr_pos += enemy_distance * -curr_spawn_direction.y
			if (curr_pos < level_rect.position.y or curr_pos > level_rect.position.y + level_rect.size.y):
				break

	#endregion

### SIGNAL ###
func _on_body_entered(body: Node2D):
	var player_direction: Vector2 = $CollisionShape2D.global_position.direction_to(body.global_position)
	var player_direction_angle := player_direction.angle()

	for boundary in $DespawnBoudary.get_children():
		boundary.get_node("CollisionShape2D").set_deferred("disabled", true)

	var detection_rect: Rect2 = Rect2($CollisionShape2D.global_position - $CollisionShape2D.shape.size / 2.0 , $CollisionShape2D.shape.size)
	var player_x_percent: float = (body.global_position.x - detection_rect.position.x) / detection_rect.size.x
	var player_y_percent: float = (body.global_position.y - detection_rect.position.y) / detection_rect.size.y
	if (only_spawn_direction == Vector2.ZERO):
		if (spawn_horizontal and !spawn_vertical):
			if (player_x_percent <= 0.5):
				curr_spawn_direction = Vector2.LEFT if spawn_on_opposite_screen_edge else Vector2.RIGHT
			else:
				curr_spawn_direction = Vector2.RIGHT if spawn_on_opposite_screen_edge else Vector2.LEFT
		elif (spawn_vertical and !spawn_horizontal):
			if (player_y_percent <= 0.5):
				curr_spawn_direction = Vector2.UP if spawn_on_opposite_screen_edge else Vector2.DOWN
			else:
				curr_spawn_direction = Vector2.DOWN if spawn_on_opposite_screen_edge else Vector2.UP
		elif (spawn_vertical and spawn_horizontal):
			var check_x_left: float = player_y_percent
			var check_x_right: float = 1.0 - player_y_percent

			if (player_y_percent <= 0.5):
				if (player_x_percent >= check_x_left and player_x_percent <= check_x_right):
					curr_spawn_direction = Vector2.UP if spawn_on_opposite_screen_edge else Vector2.DOWN
				elif player_x_percent < check_x_left:
					curr_spawn_direction = Vector2.LEFT if spawn_on_opposite_screen_edge else Vector2.RIGHT
				else:
					curr_spawn_direction = Vector2.RIGHT if spawn_on_opposite_screen_edge else Vector2.LEFT
			else:
				if (player_x_percent >= check_x_right and player_x_percent <= check_x_left):
					curr_spawn_direction = Vector2.DOWN if spawn_on_opposite_screen_edge else Vector2.UP
				elif player_x_percent < check_x_right:
					curr_spawn_direction = Vector2.LEFT if spawn_on_opposite_screen_edge else Vector2.RIGHT
				else:
					curr_spawn_direction = Vector2.RIGHT if spawn_on_opposite_screen_edge else Vector2.LEFT
	else:
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

	var screen_edge: float = get_screen_edge_position()

	for en in processed_enemy:
		if !(en):
			continue
		match curr_spawn_direction:
			Vector2.LEFT:
				if (en.global_position.x > screen_edge):
					en.queue_free()
			Vector2.RIGHT:
				if (en.global_position.x < screen_edge):
					en.queue_free()
			Vector2.UP:
				if (en.global_position.y > screen_edge):
					en.queue_free()
			Vector2.DOWN:
				if (en.global_position.y < screen_edge):
					en.queue_free()
	processed_enemy = processed_enemy.filter(func (ele): return ele and !ele.dead and !ele.is_queued_for_deletion())
	$SpawnTimer.stop()

func get_screen_edge_position() -> float:
	var camera: Camera2D = get_viewport().get_camera_2d()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size / vs.resolution_scale
	var screen_position: Vector2 = camera.get_screen_center_position() - screen_size / 2.0
	match curr_spawn_direction:
		Vector2.LEFT:
			return screen_position.x + screen_size.x
		Vector2.RIGHT:
			return screen_position.x
		Vector2.UP:
			return screen_position.y + screen_size.y
		Vector2.DOWN:
			return screen_position.y
	return 0.0

func _on_despawn_boundary_body_entered(actor: Enemy) -> void:
	if (actor in processed_enemy):
		actor.queue_free()
		processed_enemy.erase(actor)
