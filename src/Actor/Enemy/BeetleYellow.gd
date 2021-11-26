extends Enemy

enum StartingDirection {LEFT, RIGHT, UP, DOWN}
export(StartingDirection) var starting_direction


#export var starting_direction = Vector2.LEFT
var direction: Vector2
var idle = false


func _ready():
	hp = 4
	damage_on_contact = 2
	speed = Vector2(100, 100)
	acceleration = 25
	
	level = 3
	
	$RayCast2D.cast_to = Vector2(200, 200) * starting_direction #cast ray left or right 200 px




func _physics_process(_delta):
	if idle:
		var collider = $RayCast2D.get_collider()
		if collider.get_collision_layer_bit(0): #player
			fly()

	else:
		if is_on_wall():
			wait()
		
		velocity = calculate_move_velocity(velocity, direction, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)

		animate()

func fly():
	idle = false
	direction *= -1 


func wait():
	idle = true
	old_dir = move_dir
	move_dir = Vector2.ZERO

	if old_dir.x == -1:
		$AnimationPlayer.play("ClingLeftCrawlUp")
	elif old_dir.x == 1:
		$AnimationPlayer.play("ClingRightCrawlUp")
		
	$RayCast2D.cast_to.x *= -1


	

func calculate_move_velocity(linearvelocity: Vector2, move_direction: Vector2, speed: Vector2) -> Vector2:
	
	var out: = linearvelocity
	out.x = speed.x * move_direction.x
	out.y = speed.y * move_direction.y
	return out
	
func animate():
	if not is_on_wall():
		if move_dir == Vector2.LEFT:
			$AnimationPlayer.play("FlyLeft")
		if move_dir == Vector2.RIGHT:
			$AnimationPlayer.play("FlyRight")
