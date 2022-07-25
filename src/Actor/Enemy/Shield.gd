extends Enemy

export var move_dir = Vector2.LEFT

onready var ap = $AnimationPlayer
onready var bb = $BulletBlocker

func _ready():
	if disabled: return
	change_state("walk")
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = Vector2(50, 50)


func enter_defend():
	pass

func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	
	match move_dir:
		Vector2.LEFT: 
			ap.play("WalkLeft")
			#bb.scale.x = 1
			collision_layer = 32 #shield
		Vector2.RIGHT: 
			ap.play("WalkRight")
			#bb.scale.x = -1
			collision_layer = 2 #enemy
	
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, 10.0))
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
			ap.play("IdleLeft")
			#bb.scale.x = 1
			collision_layer = 32 #shield
		Vector2.RIGHT:
			ap.play("IdleRight")
			#bb.scale.x = -1
			collision_layer = 2 #enemy
	$StateTimer.start(rng.randf_range(1.0, 5.0))
	yield($StateTimer, "timeout")
	change_state("walk")

