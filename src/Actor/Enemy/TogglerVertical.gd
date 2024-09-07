extends Enemy

@export var starting_direction = Vector2.UP
var move_dir: Vector2
var look_dir: Vector2
var waiting = false
@export var wait_time = 1.0


func _ready():
	hp = 2
	damage_on_contact = 2
	speed = Vector2(100, 100)
	move_dir = starting_direction
	look_dir = starting_direction
	acceleration = 25

	reward = 2

	
func _physics_process(_delta):
	if disabled or dead: return
	velocity = calculate_move_velocity(velocity, move_dir, speed)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	animate()
	
	if is_on_floor() or is_on_ceiling():
		if waiting == false:
			wait()


func wait():
	waiting = true
	var old_dir = move_dir
	move_dir = Vector2.ZERO

	if old_dir.y == -1:
		$AnimationPlayer.play("ClingUpCrawlLeft")
	elif old_dir.y == 1:
		$AnimationPlayer.play("ClingDownCrawlLeft")

	await get_tree().create_timer(wait_time).timeout
	move_dir = Vector2(old_dir.x, old_dir.y * -1)
	waiting = false


func calculate_move_velocity(
		linear_velocity: Vector2,
		move_direction: Vector2,
		speed: Vector2
		) -> Vector2:
	
	var out: = linear_velocity
	out.x = speed.x * move_direction.x
	out.y = speed.y * move_direction.y
	return out
	
	
	
	
func animate():
	if not is_on_floor() and not is_on_ceiling():
		if move_dir == Vector2.UP:
			$AnimationPlayer.play("FlyLeft")
		if move_dir == Vector2.DOWN:
			$AnimationPlayer.play("FlyLeft")
