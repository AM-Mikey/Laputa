extends Enemy

const ICON = preload("res://assets/Actor/Enemy/ShieldIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Shield.png")

var shield_dir = Vector2.LEFT
var move_dir = Vector2.LEFT: set = set_move_dir
@export var wait_max_time = 5.0
@export var walk_max_time = 10.0
@export var defend_time = 0.4

@onready var ap = $AnimationPlayer
@onready var bb = $BulletBlocker

func setup(): #Reminder: no function called can use await
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = Vector2(50, 50)
	is_wind_affected = true
	shield_dir = $ShieldDir.direction.snappedf(1.0)
	$Sprite2D.flip_h = shield_dir.x > 0.0
	move_dir = $MoveDir.direction.snappedf(1.0)
	w.emit_signal("finished_spawn_entities_step")
	change_state("wait")

### STATES ###

func enter_walk(_last_state):
	move_dir = move_dir
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT


	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, walk_max_time))
	await $StateTimer.timeout
	change_state("wait")

func do_walk(_delta):
	if (not $FloorDetectorL.is_colliding() and move_dir.x < 0) \
	or (not $FloorDetectorR.is_colliding() and move_dir.x > 0):
		change_state("wait")
		return

	if velocity.x == 0.0:
		move_dir.x *= -1.0

	velocity = calc_velocity(move_dir)
	move_and_slide()



func enter_wait(_last_state):
	move_dir = move_dir
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, wait_max_time))
	await $StateTimer.timeout
	change_state("walk")


func enter_defend(_last_state):
	ap.play("IdleShield")
	$StateTimer.start(defend_time)
	await $StateTimer.timeout
	change_state("walk")

### HELPER ###

func set_move_dir(dir):
	move_dir = dir
	if move_dir.x * shield_dir.x >= 0.0:
		if state == "walk":
			ap.play("WalkShield")
		elif state == "wait":
			ap.play("IdleShield")
		$BulletBlocker/Left.set_deferred("disabled", move_dir != Vector2.LEFT)
		$BulletBlocker/Right.set_deferred("disabled", move_dir == Vector2.LEFT)
		$BulletBlocker/StaticBody2D/Left.set_deferred("disabled", move_dir != Vector2.LEFT)
		$BulletBlocker/StaticBody2D/Right.set_deferred("disabled", move_dir == Vector2.LEFT)
		$Hurtbox/Left.set_deferred("disabled", move_dir == Vector2.LEFT)
		$Hurtbox/Right.set_deferred("disabled", move_dir != Vector2.LEFT)
	else:
		if state == "walk":
			ap.play("WalkCake")
		elif state == "wait":
			ap.play("IdleCake")
		$BulletBlocker/Left.set_deferred("disabled", true)
		$BulletBlocker/Right.set_deferred("disabled", true)
		$BulletBlocker/StaticBody2D/Left.set_deferred("disabled", true)
		$BulletBlocker/StaticBody2D/Right.set_deferred("disabled", true)
		$Hurtbox/Left.set_deferred("disabled", false)
		$Hurtbox/Right.set_deferred("disabled", false)




### SIGNALS ###
func _on_BulletBlocker_body_entered(body):
	if body.get_collision_layer_value(7): #bullet
		if move_dir.x * shield_dir.x > 0.0:
			change_state("defend")

func _on_BulletBlocker_area_entered(area):
	if area.get_collision_layer_value(7): #bullet
		if move_dir.x * shield_dir.x > 0.0:
			change_state("defend")
