extends Enemy

const BULLET = preload("res://src/Bullet/Enemy/Carbine.tscn")

var starting_state := "walk"
@export var move_dir := Vector2.LEFT
@export var idle_max_time := 5.0
@export var walk_max_time := 10.0
@export var aim_time := 0.2
@export var reload_time := 2.0

var target: Node

@onready var ap = $AnimationPlayer
@onready var st = $StateTimer

func setup():
	change_state(starting_state)
	hp = 12
	reward = 8
	damage_on_contact = 3
	speed = Vector2(50, 50)

### STATES ###

func enter_idle():
	do_flip_check()
	ap.play("Idle")
	rng.randomize()
	st.start(rng.randf_range(1.0, idle_max_time))

func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	do_flip_check()
	ap.play("Walk")
	rng.randomize()
	st.start(rng.randf_range(1.0, walk_max_time))

func do_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		change_state("idle")
		return
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		change_state("idle")
		return
	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
		velocity = calc_velocity(velocity, move_dir, speed)
		set_up_direction(FLOOR_NORMAL)
		move_and_slide()

func enter_aim():
	velocity = Vector2(lerp(velocity.x, 0.0, 0.4), lerp(velocity.y, 0.0, 0.4))
	ap.play("Aim")
	await ap.animation_finished
	st.start(aim_time)
	await st.timeout
	change_state("shoot")

func enter_shoot():
	am.play("enemy_shoot", self)
	var bullet = BULLET.instantiate()
	bullet.position = $BulletOrigin.global_position
	bullet.origin = bullet.position #TODO: WHY not just have it set origin on ready?
	bullet.direction = move_dir
	w.middle.add_child(bullet)
	st.start(reload_time)


### HELPERS ###

func do_flip_check():
	match move_dir:
		Vector2.LEFT: 
			$Sprite2D.flip_h = false
			$PlayerDetector.scale.x = 1
			$BulletOrigin.position = Vector2(-13, -13)
		Vector2.RIGHT: 
			$Sprite2D.flip_h = true
			$PlayerDetector.scale.x = -1
			$BulletOrigin.position = Vector2(13, -13)

### SIGNALS ###

func _on_hit(_damage, blood_direction):
	if sign(blood_direction.x) == sign(move_dir.x): #shot from behind
		ap.play("Shock")
		await ap.animation_finished
		ap.play("Idle")
		move_dir.x = move_dir.x * -1
		do_flip_check()

func _on_PlayerDetector_body_entered(body):
	target = body.get_parent()
	if state != "shoot" and state != "aim":
		change_state("aim")


func _on_PlayerDetector_body_exited(body):
	target = null


func _on_StateTimer_timeout():
	match state:
		"idle":
			change_state("walk")
		"walk":
			change_state("idle")
		"shoot":
			if target:
				change_state("shoot")
			else:
				change_state("idle")
		_: pass
