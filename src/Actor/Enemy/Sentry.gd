extends Enemy

const ICON = preload("res://assets/Actor/Enemy/SentryIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Sentry0.png")
const TX_1 = preload("res://assets/Actor/Enemy/Sentry1.png")
const TX_2 = preload("res://assets/Actor/Enemy/Sentry2.png")
const TX_3 = preload("res://assets/Actor/Enemy/Sentry3.png")
const TX_4 = preload("res://assets/Actor/Enemy/Sentry4.png")

const HAIRBALL = preload("res://src/Bullet/Enemy/Hairball.tscn")
const HAIRBALL_RAIN = preload("res://src/Bullet/Enemy/HairballRain.tscn")

# difficulty = 3: Shoot rapidly upward in order in the spread cone starting from player's direction then wait for cooldown_time
# difficulty = 4: Shoot upward with random deviation defined by spread
@export var difficulty: int = 0
var max_difficulty := 4

@export var projectile_damage: int = 2

@export var fountain_bullet_in_spread: int = 8
@export var fountain_spread: float = PI / 12.0 # From [-diff_3_spread / 2.0, diff_3_spread / 2.0]
@export var fountain_force: float = 200.0
@export var diff_3_rapid_fire_time: float = 0.1

@export var diff_3_cooldown := 5.0
@export var normal_cooldown := 3.5
var cooldown_time: float


var face_dir = Vector2.LEFT
var target: Node2D = null
var first_sight_target := false

const shoot_reload_anim_time := 1.2
const reload_anim_time = 0.4
var shoot_anim_speed := 1.0

var curr_bullet_idx := 0
var rapid_fire_from_left := false

@onready var ap = $AnimationPlayer

func setup(): #Reminder: no function called can use await
	face_dir = Vector2(sign($ShootX.position.x), 0.0)
	$Sprite2D.flip_h = true if face_dir.x == 1.0 else false

	$PlayerDetector/CollisionShape2D.shape.size = $VURect.value.size
	$PlayerDetector/CollisionShape2D.position = $VURect.value.size / 2.0 + $VURect.value.position

	match difficulty:
		0:
			$Sprite2D.texture = TX_0
			hp = 4
			damage_on_contact = 1
			reward = 2
			cooldown_time = normal_cooldown
		1:
			$Sprite2D.texture = TX_1
			hp = 4
			damage_on_contact = 1
			reward = 3
			cooldown_time = normal_cooldown
		2:
			$Sprite2D.texture = TX_2
			hp = 4
			damage_on_contact = 1
			reward = 4
			cooldown_time = normal_cooldown
		3:
			$Sprite2D.texture = TX_3
			hp = 8
			damage_on_contact = 2
			reward = 6
			cooldown_time = diff_3_cooldown
		4:
			$Sprite2D.texture = TX_3
			hp = 8
			damage_on_contact = 2
			reward = 6
			cooldown_time = normal_cooldown

	shoot_anim_speed = shoot_reload_anim_time / cooldown_time
	if difficulty == 3:
		shoot_anim_speed = (shoot_reload_anim_time - reload_anim_time) / diff_3_rapid_fire_time
	shoot_anim_speed = max(1.0, shoot_anim_speed)

	w.emit_signal("finished_spawn_entities_step")
	change_state("idle")



### STATES ###

func enter_shoot(_last_state):
	if ap.current_animation == "":
		if difficulty == 3:
			var player = f.pc()
			if player:
				rapid_fire_from_left = (player.global_position.x - global_position.x < 0.0)
			if $ShootDelay.time_left <= 0.0:
				ap.play("Shoot", -1.0, shoot_anim_speed)
		else:
			ap.play("Shoot", -1.0, shoot_anim_speed)
			first_sight_target = false

func do_shoot(_delta):
	if difficulty == 0:
		face_dir = Vector2(sign($ShootX.position.x), 0.0) #face towards ShootX
	elif difficulty in [1, 2] && target:
		face_dir = Vector2(sign(target.global_position.x - global_position.x), 0.0) #face towards player
	if difficulty != 3:
		if ap.current_animation == "" && first_sight_target:
			ap.play("Shoot", -1.0, shoot_anim_speed)
			first_sight_target = false

	$Sprite2D.flip_h = true if face_dir.x == 1.0 else false
func exit_shoot(_next_state):
	if difficulty != 3:
		$ShootDelay.stop()



### HELPERS ###

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
				target_displace_x = abs($ShootX.position.x) * face_dir.x
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

		var bullet_vel_x = target_displace_x / time_travel
		var bullet_vel_y = (-0.5 * bullet_gravity * pow(time_travel, 2) - bullet_origin.y) / time_travel

		bullet.speed = Vector2(bullet_vel_x, bullet_vel_y).length()
		bullet.direction = Vector2(bullet_vel_x, bullet_vel_y).normalized()
		w.middle.add_child(bullet)

	elif difficulty == 3:
		var bullet = HAIRBALL_RAIN.instantiate()
		bullet.damage = projectile_damage
		bullet.position = global_position + bullet_origin
		bullet.swing_left_first = true
		bullet.speed = fountain_force
		var deviation_idx = curr_bullet_idx if rapid_fire_from_left else fountain_bullet_in_spread - 1 - curr_bullet_idx
		bullet.direction = Vector2.UP.rotated(-fountain_spread / 2.0 + deviation_idx * fountain_spread / (fountain_bullet_in_spread - 1))
		w.middle.add_child(bullet)
		curr_bullet_idx += 1

	elif difficulty == 4:
		var bullet = HAIRBALL_RAIN.instantiate()
		bullet.damage = projectile_damage
		bullet.position = global_position + bullet_origin
		bullet.speed = fountain_force
		bullet.direction = Vector2.UP.rotated(randf_range(-fountain_spread / 2.0, fountain_spread / 2.0))
		w.middle.add_child(bullet)
		curr_bullet_idx += 1

	am.play("enemy_shoot", self)



### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	target = body
	if difficulty != 3:
		first_sight_target = true
	change_state("shoot")

func _on_PlayerDetector_body_exited(_body):
	target = null
	if difficulty != 3:
		first_sight_target = false
	change_state("idle")

func _on_AnimationPlayer_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"Shoot":
			if state == "idle":
				if difficulty != 3:
					ap.play("Reload")
				else:
					if curr_bullet_idx < fountain_bullet_in_spread:
						ap.play("Shoot", -1.0, shoot_anim_speed)
					else:
						curr_bullet_idx = 0
						var player = f.pc()
						if player:
							rapid_fire_from_left = (player.global_position.x - global_position.x < 0.0)
						ap.play("Reload", -1.0, max(1.0, reload_anim_time / cooldown_time))
			elif state == "shoot":
				if difficulty != 3:
					ap.play("Reload", -1.0, shoot_anim_speed)
				else:
					if curr_bullet_idx < fountain_bullet_in_spread:
						ap.play("Shoot", -1.0, shoot_anim_speed)
					else:
						curr_bullet_idx = 0
						var player = f.pc()
						if player:
							rapid_fire_from_left = (player.global_position.x - global_position.x < 0.0)
						ap.play("Reload", -1.0, max(1.0, reload_anim_time / cooldown_time))
		"Reload":
			if difficulty == 3 && cooldown_time > reload_anim_time:
				$ShootDelay.start(cooldown_time - reload_anim_time)
			if state == "shoot":
				if difficulty != 3 && cooldown_time > shoot_reload_anim_time:
					$ShootDelay.start(cooldown_time - shoot_reload_anim_time)
				else:
					if difficulty != 3:
						ap.play("Shoot", -1.0, shoot_anim_speed)
						first_sight_target = false
					else:
						if $ShootDelay.time_left <= 0.0:
							ap.play("Shoot", -1.0, shoot_anim_speed)

func _on_ShootDelay_timeout() -> void:
	if state == "shoot":
		ap.play("Shoot", -1.0, shoot_anim_speed)
