extends Enemy

var starting_state = "walk"
export var move_dir = Vector2.LEFT
export var idle_max_time = 5.0
export var walk_max_time = 10.0
export var defend_time = 0.4

onready var ap = $AnimationPlayer
onready var bb = $BulletBlocker

func setup():
	change_state(starting_state)
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = Vector2(50, 50)

func bb(state: bool):
	bb.monitoring = state
	bb.monitorable = state

### STATES ###

func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	
	match move_dir:
		Vector2.LEFT: 
			ap.play("WalkLeft")
			bb(true)
			#collision_layer = 32 #shield
		Vector2.RIGHT: 
			ap.play("WalkRight")
			bb(false)
			#collision_layer = 2 #enemy
	
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
			ap.play("IdleLeft")
			bb(true)
			#collision_layer = 32 #shield
		Vector2.RIGHT:
			ap.play("IdleRight")
			bb(false)
			#collision_layer = 2 #enemy
	$StateTimer.start(rng.randf_range(1.0, idle_max_time))
	yield($StateTimer, "timeout")
	change_state("walk")


func enter_defend():
	ap.play("IdleLeft")
	$StateTimer.start(defend_time)
	yield($StateTimer, "timeout")
	change_state("walk")

### SIGNALS ###

func _on_BulletBlocker_body_entered(body):
	print("dasasdasdas")
	if body.get_collision_layer_bit(6): #bullet
		if move_dir == Vector2.LEFT:
			change_state("defend")

func _on_BulletBlocker_area_entered(area):
	if area.get_collision_layer_bit(6): #bullet
		if move_dir == Vector2.LEFT:
			change_state("defend")
