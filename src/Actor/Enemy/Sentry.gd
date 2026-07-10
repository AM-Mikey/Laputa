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
enum RapidFireFrom {LEFT, RIGHT, RANDOM}
@export var diff_3_rapid_fire_from: RapidFireFrom = RapidFireFrom.LEFT
@export var diff_3_rapid_fire_time: float = 0.1
@export var diff_3_bullet: int = 8
@export var diff_3_spread: float = PI / 6.0 # From [-diff_3_spread / 2.0, diff_3_spread / 2.0]
@export var diff_3_bullet_speed_scale: float = 1.5
@export var diff_3_bullet_max_swing_amp: float = 32.0
@export var diff_3_bullet_min_swing_amp: float = 32.0
@export var diff_3_bullet_peak_to_swing_time: float = 0.3
@export var diff_3_bullet_swing_gravity_mult: float = 0.15

var facing_right := false:
	set(val):
		$Sprite2D.flip_h = !val
		facing_right = val

var target: Node2D = null
var first_sight_target := false

const shoot_reload_anim_time := 1.2
const reload_anim_time = 0.4
var shoot_anim_speed := 1.0

var curr_bullet_idx := 0
var rapid_fire_from_left := false

@onready var ap = $AnimationPlayer

var debug_name = "Sentry8"

func setup(): #Reminder: no function called can use await
	shoot_anim_speed = shoot_reload_anim_time / cooldown_time if difficulty < 3 else (shoot_reload_anim_time - reload_anim_time) / diff_3_rapid_fire_time
	shoot_anim_speed = max(1.0, shoot_anim_speed)
	facing_right = $ShootX.position.x >= 0.0
	if difficulty == 3:
		rapid_fire_from_left = diff_3_rapid_fire_from == RapidFireFrom.LEFT

	$PlayerDetector/CollisionShape2D.shape.size = $VURect.value.size
	$PlayerDetector/CollisionShape2D.position = $VURect.value.size / 2.0 + $VURect.value.position

	hp = 4
	damage_on_contact = 1
	reward = 2
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
#func do_idle(_delta):
	#if name == debug_name:
		#print($ShootDelay.time_left, " ", ap.current_animation)

func enter_shoot(_last_state):
	if ap.current_animation == "":
		if difficulty == 3:
			if diff_3_rapid_fire_from == RapidFireFrom.RANDOM:
				rapid_fire_from_left = (randi() % 2 == 0)
			if $ShootDelay.time_left <= 0.0:
				ap.play("Shoot", -1.0, shoot_anim_speed)
		elif difficulty < 3:
			ap.play("Shoot", -1.0, shoot_anim_speed)
			first_sight_target = false

func do_shoot(_delta):
	if difficulty in [1, 2] and target:
		facing_right = target.global_position.x - global_position.x >= 0.0
	if difficulty < 3:
		if ap.current_animation == "" && first_sight_target:
			ap.play("Shoot", -1.0, shoot_anim_speed)
			first_sight_target = false


func prepare_bullet():
	if difficulty == 2 && !target:
		return

	var bullet_origin := Vector2(0.0, -12.0)

	if difficulty in [0, 1, 2]:
		var bullet = HAIRBALL.instantiate()
		bullet.damage = projectile_damage

		bullet.position = global_position + bullet_origin

		var bullet_gravity: float = bullet.base_gravity if !is_in_water else bullet.water_gravity

		var peak_displace_y: float = 0.0
		var target_displace_x: float = 0.0

		match difficulty:
			0:
				peak_displace_y = $ShootY.position.y
				target_displace_x = $ShootX.position.x
			1:
				peak_displace_y = $ShootY.position.y
				target_displace_x = abs($ShootX.position.x)
				target_displace_x *= 1.0 if facing_right else -1.0
			2:
				peak_displace_y = $ShootY.position.y
				target_displace_x = target.global_position.x - global_position.x

		if peak_displace_y >= 0.0:
			if difficulty == 2:
				peak_displace_y = -16.0 * 5.0
			else:
				peak_displace_y = -16.0

		var time_peak_to_ground = sqrt(max(-2.0 * peak_displace_y / bullet_gravity, 0.0))
		var time_peak_to_start = sqrt(max((bullet_origin.y - peak_displace_y) * 2.0 / bullet_gravity, 0.0))
		var time_travel = time_peak_to_ground + time_peak_to_start

		#if name == debug_name:
			#print(time_travel, " ", bullet_gravity)

		var bullet_vel_x = target_displace_x / time_travel
		var bullet_vel_y = (-0.5 * bullet_gravity * pow(time_travel, 2) - bullet_origin.y) / time_travel

		bullet.speed = Vector2(bullet_vel_x, bullet_vel_y).length()
		bullet.direction = Vector2(bullet_vel_x, bullet_vel_y).normalized()
		w.middle.add_child(bullet)
	else:
		var bullet = HAIRBALL_RAIN.instantiate()
		bullet.damage = projectile_damage
		bullet.position = global_position + bullet_origin
		bullet.peak_to_swing_time = diff_3_bullet_peak_to_swing_time

		bullet.speed = diff_3_force
		var deviation_idx = curr_bullet_idx if rapid_fire_from_left else diff_3_bullet - 1 - curr_bullet_idx
		bullet.direction = Vector2.UP.rotated(-diff_3_spread / 2.0 + deviation_idx * diff_3_spread / (diff_3_bullet - 1))
		bullet.max_swing_amplitude = diff_3_bullet_max_swing_amp
		bullet.min_swing_amplitude = diff_3_bullet_min_swing_amp
		bullet.swing_gravity_mult = diff_3_bullet_swing_gravity_mult
		w.middle.add_child(bullet)
		curr_bullet_idx += 1

	am.play("enemy_shoot", self)

func exit_shoot(_next_state):
	if difficulty < 3:
		$ShootDelay.stop()

### SIGNALS ###
func _on_PlayerDetector_body_entered(body):
	target = body
	if difficulty < 3:
		first_sight_target = true
	change_state("shoot")

func _on_PlayerDetector_body_exited(_body):
	target = null
	if difficulty < 3:
		first_sight_target = false
	change_state("idle")

func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Shoot":
			if state == "idle":
				if difficulty < 3:
					ap.play("Reload")
				else:
					if curr_bullet_idx < diff_3_bullet:
						ap.play("Shoot", -1.0, shoot_anim_speed)
					else:
						curr_bullet_idx = 0
						if diff_3_rapid_fire_from == RapidFireFrom.RANDOM:
							rapid_fire_from_left = (randi() % 2 == 0)
						ap.play("Reload", -1.0, max(1.0, reload_anim_time / cooldown_time))
			elif state == "shoot":
				if difficulty < 3:
					ap.play("Reload", -1.0, shoot_anim_speed)
				else:
					if curr_bullet_idx < diff_3_bullet:
						ap.play("Shoot", -1.0, shoot_anim_speed)
					else:
						curr_bullet_idx = 0
						if diff_3_rapid_fire_from == RapidFireFrom.RANDOM:
							rapid_fire_from_left = (randi() % 2 == 0)
						ap.play("Reload", -1.0, max(1.0, reload_anim_time / cooldown_time))
		"Reload":
			if difficulty == 3 && cooldown_time > reload_anim_time:
				$ShootDelay.start(cooldown_time - reload_anim_time)
			if state == "shoot":
				if difficulty < 3 && cooldown_time > shoot_reload_anim_time:
					$ShootDelay.start(cooldown_time - shoot_reload_anim_time)
				else:
					if difficulty < 3:
						ap.play("Shoot", -1.0, shoot_anim_speed)
						first_sight_target = false
					else:
						if $ShootDelay.time_left <= 0.0:
							ap.play("Shoot", -1.0, shoot_anim_speed)

func _on_ShootDelay_timeout() -> void:
	if state == "shoot":
		ap.play("Shoot", -1.0, shoot_anim_speed)
