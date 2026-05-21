extends Trigger

## Which enemy to spawn
@export_file var enemy_path: String = ""
## How many enemy per spawn
#@export var enemy_per_spawn: int = 1
## Spawn a new enemy after specified interval, given the spawner does not spawn more than [member=max_enemy_on_screen]
@export var spawn_interval: float = 5.0
## How many enemy can this spawner spawn. Will run out faster if the ScreenSpawn is bigger than 1 screen due to the spawn spreading mechanism.
## Value of -1 mean infinite spawn.
## The limit will not be replenlished when reenteed the area.
@export var spawn_limit: int = -1
## Will not turn off the spawner when the player's exit the area when false
@export var stop_on_player_exit: bool = true
## In 4 cardinal direction only
## The spawning enemy will be given a Dictionary {"dir": Vector2}
## The spawner will infer the direction from how the player enters the spawn zone.
@export var spawn_horizontal: bool = true
@export var spawn_vertical: bool = true
@export var spawn_facing_player: bool = true
## If set to any value different front Vector2.ZERO, spawn_horizontal, spawn_vertical will be ignored and spawn direction will always set to this value.
@export var spawn_direction_override: Vector2 = Vector2.ZERO
## If spawn in horizontal directions, the spawner will only take the top and bottom edges as limits.
## Similar for vertical direction, the spawner will only take the left and right edges as limits
var spawn_area: Rect2

@onready var actors = w.current_level.get_node("Actors")
@onready var ll = w.current_level.get_node("LevelLimiter")

var enemy_speed := Vector2.ZERO
var enemy_size := Vector2.ZERO

var player_in_trigger := false
var curr_spawn_direction := Vector2.ZERO:
	set(val):
		curr_spawn_direction = val

const min_screen_size: Vector2i = Vector2i(300, 300)
const max_screen_size: Vector2i = Vector2i(3000, 2000)

var processed_enemy = []
var leftover_enemy = []

# For spawn limit
var spawn_left := 100000

var sample_enemy = null
var sample_enemy_og_visible = false
var sample_enemy_og_process_mode = ProcessMode.PROCESS_MODE_INHERIT

func _ready():
	trigger_type = "screen_spawner"
	spawn_area = Rect2(-$CollisionShape2D.shape.size / 2.0, $CollisionShape2D.shape.size)
	$SpawnTimer.wait_time = spawn_interval
	spawn_area = $SpawnArea.value

	if !FileAccess.file_exists(enemy_path):
		w.emit_signal("finished_spawn_entities_step")
		printerr("ScreenSpawner %s | _ready(): Invalid enemy_path %s" % [name, enemy_path])
		return

	sample_enemy = load(enemy_path).instantiate()

	if !sample_enemy.is_in_group("ScreenSpawnerCompatible"):
		printerr("ScreenSpawner %s | _ready(): Enemy at %s isn't in ScreenSpawnerCompatible group!" % [name, enemy_path])
		sample_enemy.queue_free()
		w.emit_signal("finished_spawn_entities_step")
		return

	sample_enemy = $VUActor.spawn()
	sample_enemy_og_process_mode = sample_enemy.process_mode
	sample_enemy_og_visible = sample_enemy.visible
	sample_enemy.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	sample_enemy.global_position = Vector2(-1000000000, -1000000000)
	enemy_speed = sample_enemy.speed

	var collision_shape = null
	if sample_enemy.has_node("CollisionShape2D"):
		collision_shape = sample_enemy.get_node("CollisionShape2D")
	elif sample_enemy.has_node("Standable"):
		collision_shape = sample_enemy.get_node("Standable/CollisionShape2D")
	else:
		collision_shape = sample_enemy.get_child(0)
	enemy_size = collision_shape.shape.get_rect().size
	actors.add_child(sample_enemy)

	if (spawn_limit != -1):
		spawn_left = spawn_limit

	w.emit_signal("finished_spawn_entities_step")

func _on_SpawnTimer_timeout() -> void:
	if (spawn_limit != - 1 and spawn_left <= 0 or !sample_enemy):
		$SpawnTimer.stop()
		return

	var screen_rect: Rect2 = vs.get_screen_global_rect()
	var screen_size: Vector2 = screen_rect.size
	var level_rect: Rect2 = Rect2(ll.global_position, ll.size)
	var curr_spawn_area: Rect2 = spawn_area.intersection(screen_rect)

	var enemy_distance: float = enemy_speed.x * spawn_interval
	var enemy_distance_on_ortho: float = 0.0

	# Remove all invalid processed enemy. Including dead
	var to_be_deleted_enemy: Array = processed_enemy.filter(func (ele): return !ele or !is_instance_valid(ele) or ele.is_queued_for_deletion())
	for en in to_be_deleted_enemy:
		if is_instance_valid(en):
			en.queue_free()

	# Find the farthest spawned one on the screen. If there is no enemy or the farthest one is less than the screen edge, default to that screen edge
	var default_spawn_screen_edge: float = get_screen_edge_position()
	var curr_pos: float = default_spawn_screen_edge
	var default_distance_from_edge: float = min(enemy_size.length(), 15.0 + (enemy_size.x if curr_spawn_direction in [Vector2.RIGHT, Vector2.LEFT] else enemy_size.y))
	curr_pos += default_distance_from_edge * -(curr_spawn_direction.x if curr_spawn_direction in [Vector2.RIGHT, Vector2.LEFT] else curr_spawn_direction.y)
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
	if (enemy_spread_on_ortho_max_section < enemy_spread_on_ortho_min_section): # Avoid no spawn when the spawn area is too thin
		enemy_spread_on_ortho_max_section = enemy_spread_on_ortho_min_section

	for i in range(0, to_spawn):
		if (spawn_limit != - 1 and spawn_left <= 0):
			break
		for j in range(enemy_spread_on_ortho_min_section, enemy_spread_on_ortho_max_section + 1):
			if (spawn_limit != - 1 and spawn_left <= 0):
				break
			var curr_ortho_pos: float = near_screen_ortho + j * enemy_distance_on_ortho
			curr_ortho_pos += (-0.2 + 0.4 * randf()) * curr_spawn_area_ortho_size
			if (spawn_area_ortho_position > curr_ortho_pos or spawn_area_ortho_position + spawn_area_ortho_size < curr_ortho_pos):
				continue
			var enemy = spawn_enemy()
			if (curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT]):
				enemy.global_position.y = curr_ortho_pos
				enemy.global_position.x = curr_pos + (-0.2 + randf() * 0.1) * enemy_distance
			else:
				enemy.global_position.x = curr_ortho_pos
				enemy.global_position.y = curr_pos + (-0.2 + randf() * 0.1) * enemy_distance
			enemy.dir = curr_spawn_direction

			actors.add_child(enemy)
			processed_enemy.append(enemy)
			if (spawn_limit != -1):
				spawn_left -= 1
		if (curr_spawn_direction in [Vector2.LEFT, Vector2.RIGHT]):
			curr_pos += enemy_distance * -curr_spawn_direction.x
			if (curr_pos < level_rect.position.x or curr_pos > level_rect.position.x + level_rect.size.x):
				break
		else:
			curr_pos += enemy_distance * -curr_spawn_direction.y
			if (curr_pos < level_rect.position.y or curr_pos > level_rect.position.y + level_rect.size.y):
				break

	#endregion

### UTILITY
func spawn_enemy() -> Node:
	if (!sample_enemy):
		printerr("ScreenSpawner %s: Cannot find the sample enemy!" % [name])
		return null
	var res: Node = sample_enemy.duplicate()
	res.visible = sample_enemy_og_visible
	res.process_mode = sample_enemy_og_process_mode
	return res


### SIGNAL ###
func _exit_tree() -> void:
	for en in processed_enemy:
		if (is_instance_valid(en)):
			en.queue_free()
	for en in leftover_enemy:
		if (is_instance_valid(en) and !en.is_queued_for_deletion()):
			en.queue_free()
	if (sample_enemy):
		sample_enemy.queue_free()

func _on_body_entered(body: Node2D):
	if (!stop_on_player_exit and player_in_trigger):
		return

	var detection_rect: Rect2 = Rect2($CollisionShape2D.global_position - $CollisionShape2D.shape.size / 2.0 , $CollisionShape2D.shape.size)
	var player_x_percent: float = (body.global_position.x - detection_rect.position.x) / detection_rect.size.x
	var player_y_percent: float = (body.global_position.y - detection_rect.position.y) / detection_rect.size.y
	if (spawn_direction_override == Vector2.ZERO):
		if (spawn_horizontal and !spawn_vertical):
			if (player_x_percent <= 0.5):
				curr_spawn_direction = Vector2.LEFT if spawn_facing_player else Vector2.RIGHT
			else:
				curr_spawn_direction = Vector2.RIGHT if spawn_facing_player else Vector2.LEFT
		elif (spawn_vertical and !spawn_horizontal):
			if (player_y_percent <= 0.5):
				curr_spawn_direction = Vector2.UP if spawn_facing_player else Vector2.DOWN
			else:
				curr_spawn_direction = Vector2.DOWN if spawn_facing_player else Vector2.UP
		elif (spawn_vertical and spawn_horizontal):
			var check_x_left: float = player_y_percent
			var check_x_right: float = 1.0 - player_y_percent

			if (player_y_percent <= 0.5):
				if (player_x_percent >= check_x_left and player_x_percent <= check_x_right):
					curr_spawn_direction = Vector2.UP if spawn_facing_player else Vector2.DOWN
				elif player_x_percent < check_x_left:
					curr_spawn_direction = Vector2.LEFT if spawn_facing_player else Vector2.RIGHT
				else:
					curr_spawn_direction = Vector2.RIGHT if spawn_facing_player else Vector2.LEFT
			else:
				if (player_x_percent >= check_x_right and player_x_percent <= check_x_left):
					curr_spawn_direction = Vector2.DOWN if spawn_facing_player else Vector2.UP
				elif player_x_percent < check_x_right:
					curr_spawn_direction = Vector2.LEFT if spawn_facing_player else Vector2.RIGHT
				else:
					curr_spawn_direction = Vector2.RIGHT if spawn_facing_player else Vector2.LEFT
	else:
		curr_spawn_direction = spawn_direction_override

	player_in_trigger = true
	$SpawnTimer.start()

func _on_body_exited(body: Node2D):
	if (is_queued_for_deletion() or !stop_on_player_exit):
		return

	if (body is CharacterBody2D and body.get_collision_layer_value(1)):
		if (body.get_parent().dead or body.get_parent().is_queued_for_deletion()):
			return

	player_in_trigger = false

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
	leftover_enemy.append_array(processed_enemy)
	processed_enemy = []
	$SpawnTimer.stop()

func get_screen_edge_position() -> float:
	var screen_rect: Rect2 = vs.get_screen_global_rect()
	var screen_size: Vector2 = screen_rect.size
	var screen_position: Vector2 = screen_rect.position
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
