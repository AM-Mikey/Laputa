extends Enemy

const ICON = preload("res://assets/Actor/Enemy/ShieldIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Shield.png")

var move_dir: = Vector2.LEFT: set = set_move_dir
var defend_time: = 0.7

@onready var ap = $AnimationPlayer
@onready var bb = $BulletBlocker

func setup(): #Reminder: no function called can use await
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = Vector2(15, 15)
	is_wind_affected = true
	move_dir = $MoveDir.direction.snappedf(1.0)
	$PlayerDetection/CollisionShape2D.shape.size = $PlayerDetectArea.value.size
	$PlayerDetection/CollisionShape2D.position = $PlayerDetectArea.value.position + $PlayerDetectArea.value.size / 2.0
	state = "idle" #Prevent standng still when instantly see player on spawn
	w.emit_signal("finished_spawn_entities_step")

### STATES ###
func do_idle(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

func enter_walk(_last_state):
	move_dir = move_dir
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT

func do_walk(_delta):
	if (!$FloorDetectorL.is_colliding() and move_dir.x < 0) \
	|| (!$FloorDetectorR.is_colliding() and move_dir.x > 0) \
	|| (velocity.x == 0.0):
		move_dir.x *= -1.0

	velocity = calc_velocity(move_dir)
	move_and_slide()

func enter_defend(_last_state):
	ap.play("IdleShield")
	$StateTimer.start(defend_time)
	await $StateTimer.timeout
	change_state("walk")

### HELPER ###

func set_move_dir(dir):
	move_dir = dir
	#if move_dir.x * shield_dir.x >= 0.0:
	if state == "walk":
		ap.play("WalkShield")
	elif state == "idle":
		ap.play("IdleShield")
	$Sprite2D.flip_h = move_dir == Vector2.RIGHT
	$BulletBlocker/Left.set_deferred("disabled", move_dir != Vector2.LEFT)
	$BulletBlocker/Right.set_deferred("disabled", move_dir == Vector2.LEFT)
	$BulletBlocker/StaticBody2D/Left.set_deferred("disabled", move_dir != Vector2.LEFT)
	$BulletBlocker/StaticBody2D/Right.set_deferred("disabled", move_dir == Vector2.LEFT)
	$Hurtbox/Left.set_deferred("disabled", move_dir == Vector2.LEFT)
	$Hurtbox/Right.set_deferred("disabled", move_dir != Vector2.LEFT)
	#else:
		#if state == "walk":
			#ap.play("WalkCake")
		#elif state == "wait":
			#ap.play("IdleCake")
		#$BulletBlocker/Left.set_deferred("disabled", true)
		#$BulletBlocker/Right.set_deferred("disabled", true)
		#$BulletBlocker/StaticBody2D/Left.set_deferred("disabled", true)
		#$BulletBlocker/StaticBody2D/Right.set_deferred("disabled", true)
		#$Hurtbox/Left.set_deferred("disabled", false)
		#$Hurtbox/Right.set_deferred("disabled", false)




### SIGNALS ###
func _on_BulletBlocker_body_entered(body):
	if body.get_collision_layer_value(7): #bullet
		change_state("defend")

func _on_BulletBlocker_area_entered(area):
	if area.get_collision_layer_value(7): #bullet
		change_state("defend")

func _on_PlayerDetection_body_entered(body: Node2D) -> void:
	if state == "idle":
		$PlayerDetection.monitoring = false
		change_state("walk")
