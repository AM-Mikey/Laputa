extends Enemy

const ICON = preload("res://assets/Actor/Enemy/ShieldIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Shield.png")
const TX_1 = preload("res://assets/Actor/Enemy/Shield.png")
const TX_2  = preload("res://assets/Actor/Enemy/Shield.png")

@export var difficulty: int = 0
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
	$AttackDetection.monitoring = difficulty >= 1
	match difficulty:
		0:
			$Sprite2D.texture = TX_0
		1:
			$Sprite2D.texture = TX_1
			$Sprite2D.self_modulate = Color.GREEN
		2:
			$Sprite2D.texture = TX_2
			$Sprite2D.self_modulate = Color.RED


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
	if difficulty == 0:
		ap.play("IdleShield")
		$StateTimer.start(defend_time)
		await $StateTimer.timeout
		change_state("walk")

func do_defend(_delta):
	if difficulty >= 1:
		velocity = calc_velocity(move_dir)
		move_and_slide()

func enter_attack(_prev_state):
	ap.play("Attack")

### SETTER ###
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
	$AttackDetection.scale.x = -signf(move_dir.x)
	if $AttackDetection.scale.x == 0.0: $AttackDetection.scale.x = 1.0
	$AttackHitbox.scale.x = -signf(move_dir.x)
	if $AttackHitbox.scale.x == 1.0: $AttackHitbox.scale.x = 1.0

### UTILITY ###
func enable_attack_hitbox(val: bool):
	$AttackHitbox.monitorable = val
	$AttackHitbox.monitoring = val

func play_sound(sfx_name: String):
	am.play(sfx_name)

### SIGNALS ###
func _on_BulletBlocker_body_entered(body):
	_on_BulletBlocker_area_entered(body)

func _on_BulletBlocker_area_entered(_area):
	if (difficulty == 0) || \
		(difficulty == 1 && state == "walk"):
		change_state("defend")

func _on_PlayerDetection_body_entered(_body):
	if state == "idle":
		$PlayerDetection.set_deferred("monitoring", false)
		change_state("walk")

func _on_AttackDetection_body_entered(_body):
	if difficulty == 1 and state in ["walk", "defend"]:
		change_state("attack")

func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	if difficulty == 1:
		if anim_name == "Attack":
			change_state("walk")
