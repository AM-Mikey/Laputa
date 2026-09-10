extends Enemy

const ICON = preload("res://assets/Actor/Enemy/LarryIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Larry.png")

var move_dir: Vector2
var idle = false
var idle_time: float
var active_time: float

func setup(): #Reminder: no function called can use await
	hp = 1
	damage_on_contact = 0
	speed = Vector2(100, 100)
	reward = 0

	rng.randomize()
	move_dir = Vector2(sign(rng.randf_range(-1, 1)), 0)
	$Sprite2D.flip_h = false if move_dir == Vector2.LEFT else true
	idle_time = rng.randf_range(0.5, 2)
	active_time = rng.randf_range(2, 4)
	$Timer.start(active_time)
	is_wind_affected = true
	w.emit_signal("finished_spawn_entities_step")

func _physics_process(_delta):
	if disabled or dead: return
	velocity = calc_velocity(move_dir)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	animate()

	if is_on_wall():
		if !idle and $TurnCooldown.time_left <= 0.0:
			move_dir *= -1.0
			$Sprite2D.flip_h = !$Sprite2D.flip_h
			$TurnCooldown.start()

func wait():
	idle = true
	var old_speed = speed
	speed = Vector2.ZERO
	$Timer.start(idle_time)

	await $Timer.timeout
	rng.randomize()
	move_dir = Vector2(sign(rng.randf_range(-1, 1)), 0)
	$Sprite2D.flip_h = false if move_dir == Vector2.LEFT else true
	idle = false
	speed = old_speed
	$Timer.start(active_time)


func animate():
	if !idle:
		if velocity.length() > 1.0:
			$AnimationPlayer.play("Walk")
		else:
			$AnimationPlayer.play("Idle")
	else:
		$AnimationPlayer.play("Idle")


func _on_Timer_timeout():
	if !idle:
		wait()
