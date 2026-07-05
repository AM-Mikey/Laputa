extends Enemy

const ICON = preload("res://assets/Actor/Enemy/SentryIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Sentry.png")
const TX_1 = preload("res://assets/Actor/Enemy/Sentry.png") #WIP: Placeholder
const TX_2 = preload("res://assets/Actor/Enemy/Sentry.png") #WIP: Placeholder
const TX_3 = preload("res://assets/Actor/Enemy/Sentry.png") #WIP: Placeholder

const HAIRBALL = preload("res://src/Bullet/Enemy/Hairball.tscn")
const HAIRBALL_RAIN = preload("res://src/Bullet/Enemy/HairballRain.tscn")

@export var difficulty: int = 0
@export var cooldown_time = 2.0
@export var projectile_damage: int = 2

@export var diff_3_force: float = 300.0
@export var diff_3_spread: float = PI / 6.0 # From [-diff_3_spread / 2.0, diff_3_spread / 2.0]
@export var diff_3_bullet_max_swing_amp: float = 64.0
@export var diff_3_bullet_min_swing_amp: float = 32.0
@export var diff_3_bullet_swing_gravity_mult: float = 0.08

var facing_right := false:
	set(val):
		$Sprite2D.flip_h = !val
		facing_right = val

var target: Node2D = null

const shoot_reload_cycle_time := 1.2
var anim_speed := 1.0

@onready var ap = $AnimationPlayer

func setup(): #Reminder: no function called can use await
	hp = 4
	damage_on_contact = 1
	speed = Vector2(50, 200)
	gravity = 250
	reward = 2
	anim_speed = max(1.0, shoot_reload_cycle_time / cooldown_time)

	facing_right = $ShootWaypoint.position.x >= 0.0

	$PlayerDetector/CollisionShape2D.shape.size = $VURect.value.size
	$PlayerDetector/CollisionShape2D.position = $VURect.value.size / 2.0 + $VURect.value.position

	match difficulty:
		0:
			$Sprite2D.texture = TX_0
			$Sprite2D.self_modulate = Color.WHITE #WIP: Placeholder
		1:
			$Sprite2D.texture = TX_1
			$Sprite2D.self_modulate = Color.GREEN #WIP: Placeholder
		2:
			$Sprite2D.texture = TX_2
			$Sprite2D.self_modulate = Color.BLUE #WIP: Placeholder
		3:
			$Sprite2D.texture = TX_3
			$Sprite2D.self_modulate = Color.YELLOW #WIP: Placeholder

	w.emit_signal("finished_spawn_entities_step")
	change_state("idle")

### STATES ###
func enter_shoot(_last_state):
	if ap.current_animation == "Reload":
		ap.play("Reload", -1.0, anim_speed)
	else:
		ap.play("Shoot", -1.0, anim_speed)

func do_shoot(_delta):
	if difficulty in [1, 2] and target:
		facing_right = target.global_position.x - global_position.x >= 0.0

func prepare_bullet():
	if difficulty == 2 && !target:
		return

	var bullet = HAIRBALL_RAIN.instantiate() if difficulty == 3 else HAIRBALL.instantiate()
	bullet.damage = projectile_damage

	var bullet_origin := Vector2(0.0, -12.0)
	bullet.position = global_position + bullet_origin

	if difficulty in [0, 1, 2]:
		var peak_displace_y: float = 0.0
		var target_displace_x: float = 0.0

		match difficulty:
			0:
				peak_displace_y = $ShootWaypoint.position.y
				target_displace_x = $ShootWaypoint.position.x
			1:
				peak_displace_y = $ShootWaypoint.position.y
				target_displace_x = abs($ShootWaypoint.position.x)
				target_displace_x *= 1.0 if facing_right else -1.0
			2:
				peak_displace_y = $ShootWaypoint.position.y
				target_displace_x = target.global_position.x - global_position.x

		if peak_displace_y >= 0.0:
			if difficulty == 2:
				peak_displace_y = -16.0 * 5.0
			else:
				peak_displace_y = -16.0

		var time_peak_to_ground = sqrt(max(-2.0 * peak_displace_y / bullet.gravity, 0.0))
		var time_peak_to_start = sqrt(max((bullet_origin.y - peak_displace_y) * 2.0 / bullet.gravity, 0.0))
		var time_travel = time_peak_to_ground + time_peak_to_start

		var bullet_vel_x = target_displace_x / time_travel
		var bullet_vel_y = (-0.5 * bullet.gravity * pow(time_travel, 2) - bullet_origin.y) / time_travel

		bullet.speed = Vector2(bullet_vel_x, bullet_vel_y).length()
		bullet.direction = Vector2(bullet_vel_x, bullet_vel_y).normalized()
	else:
		bullet.speed = diff_3_force
		bullet.direction = Vector2.UP.rotated(randf_range(-diff_3_spread / 2.0, diff_3_spread / 2.0))
		bullet.max_swing_amplitude = diff_3_bullet_max_swing_amp
		bullet.min_swing_amplitude = diff_3_bullet_min_swing_amp
		bullet.swing_gravity_mult = diff_3_bullet_swing_gravity_mult

	w.middle.add_child(bullet)
	am.play("enemy_shoot", self)

func exit_shoot(_next_state):
	$ShootDelay.stop()

### SIGNALS ###
func _on_PlayerDetector_body_entered(body):
	target = body
	change_state("shoot")

func _on_PlayerDetector_body_exited(_body):
	target = null
	change_state("idle")

func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Shoot":
			if state == "idle":
				ap.play("Reload")
			elif state == "shoot":
				ap.play("Reload", -1.0, anim_speed)
		"Reload":
			if state == "shoot":
				if cooldown_time > shoot_reload_cycle_time:
					$ShootDelay.start(cooldown_time - shoot_reload_cycle_time)
				else:
					ap.play("Shoot", -1.0, anim_speed)

func _on_ShootDelay_timeout() -> void:
	if state == "shoot":
		ap.play("Shoot", -1.0, anim_speed)
