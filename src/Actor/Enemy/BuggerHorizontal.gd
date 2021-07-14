extends Enemy

export var starting_direction = Vector2.LEFT
var move_dir: Vector2
var old_dir: Vector2
var look_dir: Vector2
var waiting = false
export var wait_time = 1.0


func _ready():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(100, 100)
	move_dir = starting_direction
	look_dir = starting_direction
	acceleration = 25
	
	level = 3
	
	$RayCast2D.cast_to = Vector2(200, 200) * starting_direction #cast ray left or right 200 px




func _physics_process(delta):
	if waiting:
		#yield(get_tree().create_timer(wait_time), "timeout")
		if $RayCast2D.get_collider().get_collision_layer_bit(0): #player
			fly()

	
	if not dead:
		_velocity = calculate_move_velocity(_velocity, move_dir, speed)
		_velocity = move_and_slide(_velocity, FLOOR_NORMAL)
		
		animate()
		
		if is_on_wall():
			if waiting == false:
				wait()


func wait():
	waiting = true
	old_dir = move_dir
	move_dir = Vector2.ZERO

	if old_dir.x == -1:
		$AnimationPlayer.play("ClingLeftCrawlUp")
	elif old_dir.x == 1:
		$AnimationPlayer.play("ClingRightCrawlUp")
		
	$RayCast2D.cast_to.x *= -1

func fly():
	waiting = false
	print("bugger flying")
	move_dir = Vector2(old_dir.x * -1, old_dir.y)
	

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
	if not is_on_wall():
		if move_dir == Vector2.LEFT:
			$AnimationPlayer.play("FlyLeft")
		if move_dir == Vector2.RIGHT:
			$AnimationPlayer.play("FlyRight")
