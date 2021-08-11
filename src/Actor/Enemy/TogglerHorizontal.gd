extends Enemy

export var starting_direction = Vector2.LEFT
var move_dir: Vector2
var look_dir: Vector2
var waiting = false
export var wait_time = 1.0


func _ready():
	hp = 2
	damage_on_contact = 2
	speed = Vector2(100, 100)
	move_dir = starting_direction
	look_dir = starting_direction
	acceleration = 25
	
	level = 2
	heart_chance = 1
	experience_chance = 2
	ammo_chance = 0

func _physics_process(delta):
	if not dead:
		velocity = calculate_movevelocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)
		
		animate()
		
		if is_on_wall():
			if waiting == false:
				wait()


func wait():
	waiting = true
	var old_dir = move_dir
	move_dir = Vector2.ZERO

	if old_dir.x == -1:
		$AnimationPlayer.play("ClingLeftCrawlUp")
	elif old_dir.x == 1:
		$AnimationPlayer.play("ClingRightCrawlUp")

	yield(get_tree().create_timer(wait_time), "timeout")
	move_dir = Vector2(old_dir.x * -1, old_dir.y)
	waiting = false


func calculate_movevelocity(
		linearvelocity: Vector2,
		move_direction: Vector2,
		speed: Vector2
		) -> Vector2:
	
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
