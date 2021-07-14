extends Enemy

export var starting_direction = Vector2.LEFT
var move_dir: Vector2
var waiting = false
export var wait_time = 1.0

func _ready():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(100, 100)
	move_dir = starting_direction
	acceleration = 25
	
	level = 2

func _physics_process(delta):
	if not dead:
		_velocity = calculate_move_velocity(_velocity, move_dir, speed)
		_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
		
		animate(move_dir)
		
		if is_on_wall() or is_on_ceiling() or is_on_floor():
			if waiting == false:
				waiting = true
				wait(move_dir)
				move_dir *= -1
				yield(get_tree().create_timer(1.0), "timeout")
				waiting = false

func wait(move_dir):
	var old_speed = speed
	speed = Vector2.ZERO
	if move_dir.x != 0:
		move_dir.x *= -1
		if move_dir.x == -1:
			$AnimationPlayer.play("WaitLeft")
		if move_dir.x == 1:
			$AnimationPlayer.play("WaitRight")
	if move_dir.y !=0:
		move_dir.y *= -1
		if move_dir.y == -1:
			$AnimationPlayer.play("WaitLeft")
		if move_dir.y == 1:
			$AnimationPlayer.play("WaitRight")
	yield(get_tree(),"idle_frame")
	speed = old_speed


func calculate_move_velocity(
		linear_velocity: Vector2,
		move_direction: Vector2,
		speed: Vector2
		) -> Vector2:
	
	var out: = linear_velocity
	out.x = speed.x * move_direction.x
	out.y = speed.y * move_direction.y
	return out
	
func animate(move_dir):
	if speed != Vector2.ZERO:
		if move_dir == Vector2.LEFT:
			$AnimationPlayer.play("MoveLeft")
		if move_dir == Vector2.RIGHT:
			$AnimationPlayer.play("MoveRight")
