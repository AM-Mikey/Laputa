extends Enemy

@export var move_dir = Vector2.LEFT
@export var wait_max_time = 5.0
@export var walk_max_time = 10.0
@export var defend_time = 0.4

@onready var ap = $AnimationPlayer
@onready var bb = $BulletBlocker

func setup():
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = Vector2(50, 50)
	change_state("walk")

func bullet_block(state: bool):
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
			bullet_block(true)
			#collision_layer = 32 #shield
		Vector2.RIGHT: 
			ap.play("WalkRight")
			bullet_block(false)
			#collision_layer = 2 #enemy
	
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, walk_max_time))
	await $StateTimer.timeout
	change_state("wait")

func do_walk():
	if (not $FloorDetectorL.is_colliding() and move_dir.x < 0) \
	or (not $FloorDetectorR.is_colliding() and move_dir.x > 0):
		change_state("wait")
		return
	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
		velocity = calc_velocity(velocity, move_dir, speed)
		set_up_direction(FLOOR_NORMAL)
		move_and_slide()


func enter_wait():
	rng.randomize()
	match move_dir:
		Vector2.LEFT: 
			ap.play("IdleLeft")
			bullet_block(true)
			#collision_layer = 32 #shield
		Vector2.RIGHT:
			ap.play("IdleRight")
			bullet_block(false)
			#collision_layer = 2 #enemy
	$StateTimer.start(rng.randf_range(1.0, wait_max_time))
	await $StateTimer.timeout
	change_state("walk")


func enter_defend():
	ap.play("IdleLeft")
	$StateTimer.start(defend_time)
	await $StateTimer.timeout
	change_state("walk")

### SIGNALS ###

func _on_BulletBlocker_body_entered(body):
	if body.get_collision_layer_value(7): #bullet
		if move_dir == Vector2.LEFT:
			change_state("defend")

func _on_BulletBlocker_area_entered(area):
	if area.get_collision_layer_value(7): #bullet
		if move_dir == Vector2.LEFT:
			change_state("defend")
