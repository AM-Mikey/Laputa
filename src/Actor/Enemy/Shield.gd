extends Enemy

const ICON = preload("res://assets/Actor/Enemy/ShieldIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Shield0.png")
const TX_1 = preload("res://assets/Actor/Enemy/Shield1.png")
const TX_2  = preload("res://assets/Actor/Enemy/Shield2.png")

@export var difficulty: int = 0
var move_dir: = Vector2.LEFT: set = set_move_dir
var walk_speed = Vector2(15.0, 15.0)
var player_is_behind: = false
var bodies_on_shield: = []

var attack_damage: = 4.0
var player_in_attack_range: = false

var shield_charge_speed: = 150.0
var shield_charge_damage: = 3.0
var player_in_shield_charge_range: = false

@onready var ap = $AnimationPlayer

func setup(): #Reminder: no function called can use await
	hp = 6
	reward = 2
	damage_on_contact = 2
	speed = walk_speed
	is_wind_affected = true
	$PlayerDetection/CollisionShape2D.shape.size = $PlayerDetectArea.value.size
	$PlayerDetection/CollisionShape2D.position = $PlayerDetectArea.value.position + $PlayerDetectArea.value.size / 2.0
	match difficulty:
		0:
			$Sprite2D.texture = TX_0
		1:
			$Sprite2D.texture = TX_1
		2:
			$Sprite2D.texture = TX_2
	$AttackDetection.monitoring = difficulty >= 1
	$ShieldChargeDetection.monitoring = difficulty == 2
	move_dir = $MoveDir.direction.snappedf(1.0)

	w.emit_signal("finished_spawn_entities_step")

	change_state("idle")




### STATES ###
func enter_idle(_prev_state):
	if difficulty == 0:
		ap.play("IdleNS")
	else:
		ap.play("Idle")

func do_idle(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

	if player_is_behind and $SurpriseCooldown.time_left <= 0.0:
		change_state("surprise")
		return

func enter_walk(_prev_state):
	if difficulty == 0:
		ap.play("WalkNS")
	else:
		ap.play("Walk")

func do_walk(_delta):
	velocity = calc_velocity(move_dir)
	move_and_slide()

	if (!$FloorDetectorL.is_colliding() and move_dir.x < 0) \
	|| (!$FloorDetectorR.is_colliding() and move_dir.x > 0) \
	|| (velocity.x == 0.0):
		move_dir.x *= -1.0

	if player_is_behind and $SurpriseCooldown.time_left <= 0.0:
		change_state("surprise")
		return

	if difficulty >= 1:
		if player_in_attack_range and $AttackCooldown.time_left <= 0.0:
			change_state("attack")
			return
	if difficulty == 2:
		if player_in_shield_charge_range and $ShieldChargeCooldown.time_left <= 0.0:
			change_state("shield_charge_start")

func enter_defend(_last_state):
	if difficulty == 0:
		ap.play("DefendNS")
	else:
		ap.play("Defend")

func do_defend(_delta):
	if $DefendTimer.time_left <= 0.0:
		change_state("walk")
		return

	if player_is_behind and $SurpriseCooldown.time_left <= 0.0:
		change_state("surprise")
		return

	if difficulty >= 1:
		velocity = calc_velocity(move_dir)
		move_and_slide()

		if player_in_attack_range and $AttackCooldown.time_left <= 0.0:
			change_state("attack")
		if difficulty == 2:
			if player_in_shield_charge_range and $ShieldChargeCooldown.time_left <= 0.0:
				change_state("shield_charge_start")



func enter_surprise(_prev_state):
	am.play("surprise", self)
	if difficulty == 0:
		ap.play("SupriseNS")
	else:
		ap.play("Surprise")
	await ap.animation_finished
	if difficulty == 0:
		ap.play("RaiseNS")
	else:
		ap.play("Raise")
	await ap.animation_finished
	change_state("surprise_shield_up")

func enter_surprise_shield_up(_prev_state):
	if difficulty == 0:
		ap.play("UpNS")
	else:
		ap.play("Up")
	#$BulletBlocker/StaticBody2D.set_collision_layer_value(4, true)
	$BodyOnShieldDetection.monitoring = true
	$SurpriseShieldUpTimer.start()
	$Hurtbox/NoShield.disabled = false
	$Hurtbox/Side.disabled = true
	$Hitbox/NoShield.disabled = false
	$Hitbox/Side.disabled = true
	$BulletBlocker/Up.disabled = false
	$BulletBlocker/Side.disabled = true
	$BulletBlocker/StaticBody2D/Up.disabled = false
	$BulletBlocker/StaticBody2D/Side.disabled = true
	bodies_on_shield = []

func do_surprise_shield_up(_delta):
	if $SurpriseShieldUpTimer.time_left <= 0.0:
		change_state("surprise_end")
	elif bodies_on_shield.size() > 0 and $BodyOnShieldTimer.time_left <= 0.0:
		change_state("surprise_launch")

func exit_surprise_shield_up(_next_state):
	$SurpriseShieldUpTimer.paused = false
	$SurpriseShieldUpTimer.stop()
	$BodyOnShieldDetection.monitoring = false
	$BodyOnShieldTimer.stop()


func enter_surprise_launch(_prev_state):
	if difficulty == 0:
		ap.play("LaunchNS")
	else:
		ap.play("Launch")
	await ap.animation_finished
	change_state("surprise_end")


func launch():
	const launch_velocity: Vector2 = Vector2(0, -500.0)
	for body in bodies_on_shield:
		body.get_parent().velocity.y += launch_velocity

func enter_surprise_end(_prev_state):
	$Hurtbox/NoShield.disabled = true
	$Hurtbox/Side.disabled = false
	$Hitbox/NoShield.disabled = true
	$Hitbox/Side.disabled = false
	$BulletBlocker/Up.disabled = true
	$BulletBlocker/Side.disabled = false
	$BulletBlocker/StaticBody2D/Up.disabled = true
	$BulletBlocker/StaticBody2D/Side.disabled = false
	#$BulletBlocker/StaticBody2D.set_collision_layer_value(4, false)
	if difficulty == 0:
		ap.play("LowerNS")
	else:
		ap.play("Lower")
	await ap.animation_finished
	$SurpriseCooldown.start()
	change_state("walk")






func enter_attack(_prev_state):
	ap.play("Attack")

func exit_attack(_next_state):
	$AttackCooldown.start()


func enter_shield_charge_start(_prev_state):
	ap.play("ShieldChargeStart")
	speed = Vector2(shield_charge_speed, shield_charge_speed)

func enter_shield_charge(_prev_state):
	enable_shield_charge_hitbox(true)
	ap.play("ShieldCharge")
	await get_tree().create_timer($ShieldChargeDetection/CollisionShape2D.shape.size.x / shield_charge_speed).timeout
	if state == "shield_charge":
		change_state("shield_charge_end")

func do_shield_charge(_prev_state):
	if (!$FloorDetectorL.is_colliding() and move_dir.x < 0) \
	|| (!$FloorDetectorR.is_colliding() and move_dir.x > 0) \
	|| (velocity.x == 0.0):
		change_state("shield_charge_end")
		return

	velocity = calc_velocity(move_dir)
	move_and_slide()

func enter_shield_charge_end(_prev_state):
	enable_shield_charge_hitbox(false)
	if player_in_attack_range:
		ap.play("Attack")
	else:
		ap.play("ShieldChargeEnd")
	await get_tree().create_timer(1.0).timeout
	change_state("walk")

func do_shield_charge_end(_delta):
	var no_moving_forward := false
	if (!$FloorDetectorL.is_colliding() and move_dir.x < 0) \
	|| (!$FloorDetectorR.is_colliding() and move_dir.x > 0) \
	|| (velocity.x == 0.0):
		no_moving_forward = true
		return

	velocity.x = lerp(velocity.x, 0.0, 0.08)
	if no_moving_forward: velocity.x = 0.0
	move_and_slide()

	if player_in_attack_range && ap.current_animation == "ShieldChargeEnd":
		ap.play("ShieldChargeEndAttack")

func exit_shield_charge_end(_next_state):
	speed = walk_speed
	enable_shield(true)
	$ShieldChargeCooldown.start()


### SETTER ###
func set_move_dir(dir):
	move_dir = dir
	$Sprite2D.flip_h = move_dir.x >= 0.0
	var scale_x_value: = -signf(move_dir.x)
	if scale_x_value == 0.0: scale_x_value = 1.0
	$Hurtbox.scale.x = scale_x_value
	$Hitbox.scale.x = scale_x_value
	$BulletBlocker.scale.x = scale_x_value
	#$BulletBlocker/StaticBody2D.scale.x = scale_x_value
	$PlayerBehindDetection.scale.x = scale_x_value
	$AttackDetection.scale.x = scale_x_value
	$AttackHitbox.scale.x = scale_x_value
	$ShieldChargeDetection.scale.x = scale_x_value
	$ShieldChargeHitbox.scale.x = scale_x_value


### UTILITY ###
func enable_shield(val: bool):
	$BulletBlocker/Left.set_deferred("disabled", !val || move_dir != Vector2.LEFT)
	$BulletBlocker/Right.set_deferred("disabled", !val || move_dir == Vector2.LEFT)
	$BulletBlocker/StaticBody2D/Left.set_deferred("disabled", !val || move_dir != Vector2.LEFT)
	$BulletBlocker/StaticBody2D/Right.set_deferred("disabled", !val || move_dir == Vector2.LEFT)

func enable_attack_hitbox(val: bool):
	$AttackHitbox.monitorable = val
	$AttackHitbox.monitoring = val

func enable_shield_charge_hitbox(val: bool):
	$ShieldChargeHitbox.monitorable = val
	$ShieldChargeHitbox.monitoring = val

func play_sound(sfx_name: String):
	am.play(sfx_name)

### SIGNALS ###
func _on_BulletBlocker_body_entered(body):
	_on_BulletBlocker_area_entered(body)

func _on_BulletBlocker_area_entered(_area):
	$DefendTimer.start()
	if state == "walk":
		change_state("defend")

func _on_PlayerDetection_body_entered(_body):
	if state == "idle":
		$PlayerDetection.set_deferred("monitoring", false)
		change_state("walk")

func _on_AttackDetection_body_entered(_body):
	player_in_attack_range = true

func _on_AttackDetection_body_exited(_body):
	player_in_attack_range = false

func _on_PlayerBehindDetection_body_entered(_body):
	player_is_behind = true

func _on_PlayerBehindDetection_body_exited(_body: Node2D) -> void:
	player_is_behind = false

func _on_BodyOnShieldDetection_body_entered(body):
	if body != $PhysicsLayerBody:
		$BodyOnShieldTimer.start()
		$SurpriseShieldUpTimer.paused = true
		bodies_on_shield.append(body)

func _on_BodyOnShieldDetection_body_exited(body):
	if body != $PhysicsLayerBody:
		$BodyOnShieldTimer.stop()
		$SurpriseShieldUpTimer.paused = false
		bodies_on_shield.erase(body)

func _on_ShieldChargeDetection_body_entered(_body):
	player_in_shield_charge_range = true

func _on_ShieldChargeDetection_body_exited(_body):
	player_in_shield_charge_range = false

func _on_Attack_hitbox_body_entered(body, hitbox_name):
	#breakable
	if body.get_collision_layer_value(9):
		var break_method = "cut" if hitbox_name == "Attack" else "cut"
		body.on_break(break_method)
	#player
	if body.get_collision_layer_value(17):
		var damage = attack_damage if hitbox_name == "Attack" else shield_charge_damage
		var knockback = move_dir * 10.0 if hitbox_name == "Attack" else move_dir * 50.0
		body.get_parent().hit(damage, knockback)

func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	if difficulty == 1:
		if state == "attack" && anim_name == "Attack":
			change_state("walk")
	elif difficulty == 2:
		if state == "attack" && anim_name == "Attack":
			change_state("walk")
		elif state == "shield_charge_start" && anim_name == "ShieldChargeStart":
			change_state("shield_charge")
