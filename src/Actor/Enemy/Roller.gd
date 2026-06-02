extends Enemy

const ICON = preload("res://assets/Actor/Enemy/RollerIcon.png")

@export var start_dir = Vector2.LEFT

var move_dir

@onready var prev_global_position := global_position
var stuck := false
var stuck_grace_timer := 0.1
var stuck_timer := 0.0

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


func _on_physics_process(delta):
	if disabled or dead: return
	velocity = calc_velocity(move_dir, true, false, false)

	if is_on_floor(): # Avoid getting stuck on weird geometry
		velocity.y = 0.0
	move_and_slide()
	animate()

	if (prev_global_position - global_position).length() <= 0.1:
		if (stuck_timer <= stuck_grace_timer):
			stuck_timer += delta
		else:
			stuck = true
	else:
		stuck = false
		stuck_timer = 0.0

	if ($TurnTimer.time_left <= 0):
		var wall_contact = (move_dir.x > 0 and ($R1.is_colliding() or $R2.is_colliding())) \
							or (move_dir.x <= 0 and ($L1.is_colliding() or $L2.is_colliding()))

		if wall_contact and !stuck:
			move_dir *= -1
			am.play("enemy_jump", self)
			$TurnTimer.start()

	prev_global_position = global_position

func animate():
	var displacement = (prev_global_position - global_position) / get_physics_process_delta_time()
	$AnimationPlayer.play("Roll", -1.0, displacement.length() / 80.0)
	if !stuck:
		match move_dir:
			Vector2.LEFT: $Sprite2D.flip_h = false
			Vector2.RIGHT: $Sprite2D.flip_h = true
