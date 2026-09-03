extends Enemy

const ICON = preload("res://assets/Actor/Enemy/ShieldIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Shield0.png")
const TX_1 = preload("res://assets/Actor/Enemy/Shield1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Shield2.png")

@export var difficulty: int = 0
var move_dir: = Vector2.LEFT: set = set_move_dir
const walk_speed: = Vector2(15.0, 15.0)
const defend_speed: = Vector2(5.0, 5.0)

var bodies_on_shield: = []
var bodies_on_shield_ban: = []
const launch_velocity: Vector2 = Vector2(0, -500.0)

var attack_damage: = 3.0
var player_in_attack_range: = false

var shield_charge_distance: = 100.0
var shield_charge_speed: = 150.0
var shield_charge_damage: = 3.0
var player_in_shield_charge_range: = false

var first_frame := true
var prev_global_position := Vector2.ZERO

@onready var ap = $AnimationPlayer

func setup(): #Reminder: no function called can use await
	speed = walk_speed
	is_wind_affected = true
	match difficulty:
		0:
			$Sprite2D.texture = TX_0
			$SurpriseShieldUpTimer.wait_time = 1.5
			hp = 6
			reward = 2
			damage_on_contact = 2
		1:
			$Sprite2D.texture = TX_1
			$SurpriseShieldUpTimer.wait_time = 1.0
			hp = 6
			reward = 3
			damage_on_contact = 2
		2:
			$Sprite2D.texture = TX_2
			$SurpriseShieldUpTimer.wait_time = 0.8
			hp = 6
			reward = 4
			damage_on_contact = 2
	$AttackDetection.monitoring = difficulty >= 1
	$ShieldChargeDetection.monitoring = difficulty == 2
	$ShieldChargeDetection/CollisionShape2D.shape.size.x = shield_charge_distance + 20.0
	$ShieldChargeDetection/CollisionShape2D.position = -$ShieldChargeDetection/CollisionShape2D.shape.size / 2.0
	$Armor.add_collision_exception_with(self)
	move_dir = $MoveDir.direction.snappedf(1.0)

	w.emit_signal("finished_spawn_entities_step")

	change_state("idle")
	prev_global_position = global_position

func _on_hit(_damage, _blood_direction, hitbox):
	if state in ["idle", "walk", "defend"]:
		var hurtbox = $Hurtbox/Side
		var hurtbox_rect: Rect2 = Rect2(hurtbox.global_position - hurtbox.shape.size / 2.0, $Hurtbox/Side.shape.size)
		var bullet_pos = hitbox.global_position - hurtbox.global_position
		if bullet_pos.x * move_dir.x < 0.0 \
			&& hitbox.global_position.y >= hurtbox_rect.position.y && hitbox.global_position.y <= hurtbox_rect.end.y \
			&& $SurpriseCooldown.time_left <= 0.0:
			change_state("surprise")
	elif state == "surprise_shield_up":
		if difficulty == 0:
			ap.play("UpHurtNS")
		else:
			ap.play("UpHurt")

### STATES ###
func enter_idle(_prev_state):
	if difficulty == 0:
		ap.play("IdleNS")
	else:
		ap.play("Idle")

func do_idle(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

	if difficulty >= 1:
		if player_in_attack_range && $AttackCooldown.time_left <= 0.0:
			change_state("attack")
			return
	if difficulty == 2:
		if check_player_in_shield_charge_range() && $ShieldChargeCooldown.time_left <= 0.0:
			change_state("shield_charge_start")

func enter_walk(_prev_state):
	if difficulty == 0:
		ap.play("WalkNS")
	else:
		ap.play("Walk")

func do_walk(delta):
	velocity = calc_velocity(move_dir)
	move_and_slide()

	if (!$FloorDetectorL.is_colliding() && move_dir.x < 0) \
	|| (!$FloorDetectorR.is_colliding() && move_dir.x > 0) \
	|| (velocity.x == 0.0):
		if !first_frame:
			move_dir.x *= -1.0

	if (prev_global_position - global_position).length() <= walk_speed.x * delta * 0.5:
		global_position.y -= 1.0 * delta

	if difficulty >= 1:
		if player_in_attack_range && $AttackCooldown.time_left <= 0.0:
			change_state("attack")
			return
	if difficulty == 2:
		if check_player_in_shield_charge_range() && $ShieldChargeCooldown.time_left <= 0.0:
			change_state("shield_charge_start")

	if first_frame: first_frame = false
	prev_global_position = global_position

func enter_defend(_last_state):
	if difficulty == 0:
		ap.play("DefendNS")
	else:
		ap.play("WalkDefend")
		speed = defend_speed

func do_defend(_delta):
	if $DefendTimer.time_left <= 0.0:
		change_state("walk")
		return

	if difficulty >= 1:
		velocity = calc_velocity(move_dir)
		move_and_slide()

		if player_in_attack_range && $AttackCooldown.time_left <= 0.0:
			change_state("attack")
		if difficulty == 2:
			if check_player_in_shield_charge_range() && $ShieldChargeCooldown.time_left <= 0.0:
				change_state("shield_charge_start")

func exit_defend(_next_state):
	speed = walk_speed


func enter_surprise(_prev_state):
	if difficulty == 0:
		ap.play("SurpriseNS")
	else:
		ap.play("Surprise")
	await ap.animation_finished
	if difficulty == 0:
		ap.play("RaiseNS")
	else:
		ap.play("Raise")
	await ap.animation_finished
	change_state("surprise_shield_up")

func do_surprise(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

func enter_surprise_shield_up(_prev_state):
	if difficulty == 0:
		ap.play("UpNS")
	else:
		ap.play("Up")
	$Armor.set_collision_layer_value(10, true)
	$BodyOnShieldDetection.monitoring = true
	$BodyOnShieldBanDetection.monitoring = true
	$SurpriseShieldUpTimer.start()
	$Hurtbox/NoShield.disabled = false
	$Hurtbox/Side.disabled = true
	$Hitbox/NoShield.disabled = false
	$Hitbox/Side.disabled = true
	$Armor/Up.disabled = false
	$Armor/Side.disabled = true
	$Armor.block_dir = Vector2.UP
	bodies_on_shield = []
	bodies_on_shield_ban = []

func do_surprise_shield_up(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

	if $SurpriseShieldUpTimer.time_left <= 0.0:
		change_state("surprise_end")
	elif get_valid_body_on_shield().size() > 0:
		change_state("surprise_launch")

func exit_surprise_shield_up(_next_state):
	$SurpriseShieldUpTimer.paused = false
	$SurpriseShieldUpTimer.stop()


func enter_surprise_launch(_prev_state):
	if difficulty == 0:
		ap.play("LaunchNS")
	else:
		ap.play("Launch")
	await ap.animation_finished
	change_state("surprise_end")

func do_surprise_launch(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()


func enter_surprise_end(_prev_state):
	move_dir = -move_dir
	$BodyOnShieldDetection.monitoring = false
	$BodyOnShieldBanDetection.monitoring = false
	$Hurtbox/NoShield.disabled = true
	$Hurtbox/Side.disabled = false
	$Hitbox/NoShield.disabled = true
	$Hitbox/Side.disabled = false
	$Armor/Up.disabled = true
	$Armor/Side.disabled = false
	$Armor.block_dir = Vector2.LEFT
	$Armor.set_collision_layer_value(10, false)
	if difficulty == 0:
		ap.play("LowerNS")
	else:
		ap.play("Lower")
	await ap.animation_finished
	$SurpriseCooldown.start()
	change_state("walk")

func do_surprise_end(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()




func enter_attack(_prev_state):
	ap.play("Slash")

func do_attack(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

func exit_attack(_next_state):
	$AttackCooldown.start()



func enter_shield_charge_start(_prev_state):
	speed = Vector2(shield_charge_speed, shield_charge_speed)
	ap.play("ChargeReady")
	await ap.animation_finished
	change_state("shield_charge")

func do_shield_charge_start(_delta):
	velocity = calc_velocity(Vector2.ZERO)
	move_and_slide()

func enter_shield_charge(_prev_state):
	$ShieldChargeHitbox.monitorable = true
	$ShieldChargeHitbox.monitoring = true
	$Hitbox.monitorable = false
	$Hitbox.monitoring = false
	play_sound("shield_charge_start")

	ap.play("Charge")
	$ShieldChargeTimer.start(shield_charge_distance / shield_charge_speed)

func do_shield_charge(_prev_state):
	velocity = calc_velocity(move_dir)
	move_and_slide()

	if (is_on_floor()  \
	&& ((!$FloorDetectorL.is_colliding() && move_dir.x < 0) \
	|| (!$FloorDetectorR.is_colliding() && move_dir.x > 0))) \
	|| velocity.x == 0.0 \
	|| $ShieldChargeTimer.time_left <= 0.0 :
		change_state("shield_charge_end")

func enter_shield_charge_end(_prev_state):
	$ShieldChargeHitbox.monitorable = false
	$ShieldChargeHitbox.monitoring = false
	$Hitbox.monitorable = true
	$Hitbox.monitoring = true
	ap.play("ChargeSlash")

	await ap.animation_finished
	change_state("walk")

func do_shield_charge_end(_delta):
	var no_moving_forward := false
	if (is_on_floor()  \
	&& ((!$FloorDetectorL.is_colliding() && move_dir.x < 0) \
	|| (!$FloorDetectorR.is_colliding() && move_dir.x > 0))):
		no_moving_forward = true
		return

	velocity.x = lerp(velocity.x, 0.0, 0.08)
	if no_moving_forward: velocity.x = 0.0
	move_and_slide()

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
	$Armor.scale.x = scale_x_value
	$AttackDetection.scale.x = scale_x_value
	$AttackHitbox.scale.x = scale_x_value
	$ShieldChargeDetection.scale.x = scale_x_value
	$ShieldChargeHitbox.scale.x = scale_x_value


### UTILITY ###
func enable_shield(val: bool):
	$Armor/Side.set_deferred("disabled", !val)

func enable_attack_hitbox(val: bool):
	$AttackHitbox.monitorable = val
	$AttackHitbox.monitoring = val

func play_sound(sfx_name: String):
	am.play(sfx_name, self)

func set_sprite_offset():
	$Sprite2D.position = Vector2(8.0, -16.0) * Vector2(move_dir.x, 1.0)

func launch():
	for body in get_valid_body_on_shield():
		if body.get_collision_layer_value(16):
			var main_body = body.get_parent()
			if main_body is RigidBody2D:
				main_body.linear_velocity += launch_velocity
			else:
				main_body.velocity += launch_velocity
		if body.get_collision_layer_value(1):
			body.get_parent().velocity += launch_velocity

func check_player_in_shield_charge_range() -> bool:
	if !f.pc() || !player_in_shield_charge_range: return false
	var ray_param: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	ray_param.from = $CollisionShape2D.global_position
	ray_param.to = f.pc().get_node("CollisionShape2D").global_position
	ray_param.collision_mask = 1 + 8
	ray_param.collide_with_bodies = true
	ray_param.collide_with_areas = false
	var physics_world: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var collision = physics_world.intersect_ray(ray_param)
	if !collision.is_empty() && collision["collider"] is not TileMapLayer && collision["collider"].get_collision_layer_value(1):
		return true
	return false

func update_actor_on_shield():
	var valid_bodies_size = get_valid_body_on_shield().size()
	if valid_bodies_size > 0:
		$SurpriseShieldUpTimer.paused = true
	else:
		$SurpriseShieldUpTimer.paused = false

func get_valid_body_on_shield() -> Array:
	var result = bodies_on_shield.filter(func (ele): return ele not in bodies_on_shield_ban)
	return result


### SIGNALS ###
func _on_Armor_blocked(body: Variant, shield_body: Variant) -> void:
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

func _on_BodyOnShieldDetection_body_entered(body):
	if body != $PhysicsLayerBody:
		bodies_on_shield.append(body)
		update_actor_on_shield()

func _on_BodyOnShieldDetection_body_exited(body):
	if body != $PhysicsLayerBody:
		bodies_on_shield.erase(body)
		update_actor_on_shield()

func _on_BodyOnShieldBanDetection_body_entered(body: Node2D) -> void:
	if body != $PhysicsLayerBody:
		bodies_on_shield_ban.append(body)
		update_actor_on_shield()

func _on_BodyOnShieldBanDetection_body_exited(body: Node2D) -> void:
	if body != $PhysicsLayerBody:
		bodies_on_shield_ban.erase(body)
		update_actor_on_shield()

func _on_ShieldChargeDetection_body_entered(_body):
	player_in_shield_charge_range = true

func _on_ShieldChargeDetection_body_exited(_body):
	player_in_shield_charge_range = false

func _on_Attack_hitbox_body_entered(body, hitbox_name):
	#breakable
	if body.get_collision_layer_value(9):
		var break_method = "cut" if hitbox_name == "Attack" else "cut"
		body.get_parent().on_break(break_method)
	#player
	if body.get_collision_layer_value(17):
		var player = body.get_parent()
		if hitbox_name == "Attack":
			player.hit(attack_damage, Vector2(signf(move_dir.x), 0.0), $AttackHitbox)
		else:
			var knockback: = Vector2(100.0 * move_dir.x, -20.0)
			player.hit(shield_charge_damage, knockback, $ShieldChargeHitbox)

func _on_AnimationPlayer_animation_finished(anim_name):
	if state == "surprise_shield_up" && anim_name in ["UpHurtNS", "UpHurt"]:
		if difficulty == 0:
			ap.play("UpNS")
		else:
			ap.play("Up")
		return
	if difficulty > 0:
		if state == "attack" && anim_name == "Slash":
			change_state("walk")
