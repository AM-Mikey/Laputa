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
	change_state("wait")


### STATES ###

func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		set_move_dir(Vector2.RIGHT)
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		set_move_dir(Vector2.LEFT)


	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, walk_max_time))
	await $StateTimer.timeout
	change_state("wait")

func do_walk():
	if (not $FloorDetectorL.is_colliding() and move_dir.x < 0) \
	or (not $FloorDetectorR.is_colliding() and move_dir.x > 0):
		change_state("wait")
		return
	if velocity.x == 0.0:
		move_dir *= Vector2(-1,0)

	velocity = calc_velocity(velocity, move_dir, speed)
	move_and_slide()



func enter_wait():
	set_move_dir(move_dir)
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, wait_max_time))
	await $StateTimer.timeout
	change_state("walk")


func enter_defend():
	ap.play("IdleLeft")
	$StateTimer.start(defend_time)
	await $StateTimer.timeout
	change_state("walk")

### HELPER ###

func set_move_dir(dir):
	move_dir = dir
	match move_dir:
		Vector2.LEFT:
			ap.play("WalkLeft")
			$BulletBlocker/Left.set_deferred("disabled", false)
			$BulletBlocker/Right.set_deferred("disabled", true)
			$Hurtbox/Left.set_deferred("disabled", true)
			$Hurtbox/Right.set_deferred("disabled", false)
		Vector2.RIGHT:
			ap.play("WalkRight")
			$BulletBlocker/Left.set_deferred("disabled", true)
			$BulletBlocker/Right.set_deferred("disabled", false)
			$Hurtbox/Left.set_deferred("disabled", false)
			$Hurtbox/Right.set_deferred("disabled", true)



### SIGNALS ###

func _on_BulletBlocker_body_entered(body):
	if body.get_collision_layer_value(7): #bullet
		if move_dir == Vector2.LEFT:
			change_state("defend")

func _on_BulletBlocker_area_entered(area):
	if area.get_collision_layer_value(7): #bullet
		if move_dir == Vector2.LEFT:
			change_state("defend")
