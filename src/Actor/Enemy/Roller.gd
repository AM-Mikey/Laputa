extends Enemy

const ICON = preload("res://assets/Actor/Enemy/RollerIcon.png")

@export var start_dir = Vector2.LEFT

var move_dir

func setup(): #Reminder: no function called can use await
	hp = 3
	reward = 2
	damage_on_contact = 2
	speed = Vector2(60, 60)
	acceleration = 50
	gravity = 200
	if (velocity != Vector2.ZERO):
		move_dir = Vector2(signf(velocity.x), 0.0)
	else:
		move_dir = start_dir
	set_up_direction(FLOOR_NORMAL)
	animate()
	w.emit_signal("finished_spawn_entities_step")


func _on_physics_process(_delta):
	if disabled or dead: return
	velocity = calc_velocity(move_dir, true, false, false)
	#if (name == "SpawnHole2"):
		#print("A ", velocity)
	move_and_slide()
	#if (name == "SpawnHole2"):
		#print(velocity)

	if ($TurnTimer.time_left <= 0):
		var wall_contact = (move_dir.x > 0 and ($R1.is_colliding() or $R2.is_colliding())) \
							or (move_dir.x <= 0 and ($L1.is_colliding() or $L2.is_colliding()))

		if wall_contact:
			move_dir *= -1
			am.play("enemy_jump", self)
			animate()
			$TurnTimer.start()

func animate():
	$AnimationPlayer.play("Roll")
	match move_dir:
		Vector2.LEFT: $Sprite2D.flip_h = false
		Vector2.RIGHT: $Sprite2D.flip_h = true
