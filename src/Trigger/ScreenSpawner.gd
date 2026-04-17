extends Trigger

## Which enemy to spawn
@export var enemy_path: String = ""
## Number of the same enemy on screen
@export var max_enemy_on_screen: int = 8
## Spawn a new enemy after specified interval, given the spawner does not spawn more than [member=max_enemy_on_screen]
@export var spawn_interval: float = 5.0
## If [true], the spawner will infer the direction from the player and spawn on the opposite side of the player's screen.
## The spawning enemy will be given a Dictionary {"dir": Vector2}.
## Can only take one of the 4 cardinal direction
@export var direction_dependence: bool = true
## In global position
@export var spawn_area: Rect2

@onready var actors = w.current_level.get_node("Actors")

var player_in_trigger := false
var spawn_dir := Vector2.ZERO
var enemy_on_screen_count := 0

func _ready():
	trigger_type = "ScreenSpawner"
	spawn_area = Rect2($CollisionShape2D.global_position - $CollisionShape2D.shape.size / 2.0, $CollisionShape2D.shape.size)
	$SpawnTimer.wait_time = spawn_interval
	$SpawnTimer.start()

func _on_body_entered(body: Node2D):
	var player_direction: Vector2 = $CollisionShape2D.global_position.direction_to(body.global_position)
	var player_direction_angle := player_direction.angle()
	if (abs(player_direction_angle) <= PI / 4.0): # Player approach from the right
		spawn_dir = Vector2.RIGHT
	elif (player_direction_angle < 3.0 * PI / 4.0 and player_direction_angle > PI / 4.0): # Player approach from the top
		spawn_dir = Vector2.UP
	elif (player_direction_angle > -3.0 * PI / 4.0 and player_direction_angle < -PI / 4.0): # Player approach from the bottom
		spawn_dir = Vector2.DOWN
	else: # Player approach from the left
		spawn_dir = Vector2.LEFT


	player_in_trigger = true
	$SpawnTimer.start()

func _on_body_exited(_body: Node2D):
	player_in_trigger = false
	$SpawnTimer.stop()


func _on_SpawnTimer_timeout() -> void:
	if !enemy_path or !FileAccess.file_exists(enemy_path):
		push_error("ScreenSpawner: No valid enemy at ", enemy_path)
		queue_free()
		return

	var enemy = load(enemy_path).instantiate()
	enemy.set("dir", spawn_dir)
	var spawn_area_center: Vector2 = spawn_area.get_center()
	match spawn_dir:
		Vector2.RIGHT, Vector2.LEFT:
			enemy.global_position.y = (randf() - 0.5) * spawn_area.size.y + spawn_area_center.y
			enemy.global_position.x = spawn_area.position.x if spawn_dir == Vector2.RIGHT else spawn_area.position.x + spawn_area.size.x
		Vector2.DOWN, Vector2.UP:
			enemy.global_position.x = (randf() - 0.5) * spawn_area.size.x + spawn_area_center.x
			enemy.global_position.y = spawn_area.position.y if spawn_dir == Vector2.DOWN else spawn_area.position.y + spawn_area.size.y
	actors.add_child(enemy)
