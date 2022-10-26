extends Enemy

var starting_state = "walk"
export var move_dir = Vector2.LEFT
export var idle_max_time = 5.0
export var walk_max_time = 10.0
export var defend_time = 0.4

onready var ap = $AnimationPlayer

func setup():
	change_state(starting_state)
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = Vector2(50, 50)


### STATES ###

func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	
	match move_dir:
		Vector2.LEFT: 
			$Sprite.flip_h = false
		Vector2.RIGHT: 
			$Sprite.flip_h = true
	ap.play("Walk")
	
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, walk_max_time))
	yield($StateTimer, "timeout")
	change_state("idle")

func do_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		change_state("idle")
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		change_state("idle")
	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
		velocity = get_velocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)


func enter_idle():
	rng.randomize()
	match move_dir:
		Vector2.LEFT: 
			$Sprite.flip_h = false
		Vector2.RIGHT:
			$Sprite.flip_h = true
	ap.play("Idle")
	$StateTimer.start(rng.randf_range(1.0, idle_max_time))
	yield($StateTimer, "timeout")
	change_state("walk")


### SIGNALS ###


