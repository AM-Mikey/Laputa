extends Enemy

const ICON = preload("res://assets/Actor/Enemy/SentryIcon.png")

const TX_0 = preload("res://assets/Actor/Enemy/Sentry.png")

const HAIRBALL = preload("res://src/Bullet/Enemy/Hairball.tscn")

@export var cooldown_time = 2.0
@export var projectile_damage: int = 2

var shoot_displace_x := 0.0
var shoot_height := 0.0

var move_dir: Vector2

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
	shoot_displace_x = $ShootPosition.position.x
	shoot_height = abs($ShootPosition.position.y)
	$Sprite2D.flip_h = shoot_displace_x >= 0.0

	w.emit_signal("finished_spawn_entities_step")
	change_state("idle")

### STATES ###
func enter_shoot(_last_state):
	if ap.current_animation == "Reload":
		ap.play("Reload", -1.0, anim_speed)
	else:
		ap.play("Shoot", -1.0, anim_speed)

func prepare_bullet():
	am.play("enemy_shoot", self)
	var bullet = HAIRBALL.instantiate()
	bullet.damage = projectile_damage

	var bullet_origin := Vector2(0.0, -12.0)
	bullet.position = global_position + bullet_origin

	var peak_displace_y = -shoot_height
	var target_displace_x = shoot_displace_x

	var time_peak_to_ground = sqrt(-2.0 * peak_displace_y / bullet.gravity)
	var time_peak_to_start = sqrt(max((bullet_origin.y - peak_displace_y) * 2.0 / bullet.gravity, 0.0))
	var time_travel = time_peak_to_ground + time_peak_to_start

	var bullet_vel_x = target_displace_x / time_travel
	var bullet_vel_y = (-0.5 * bullet.gravity * pow(time_travel, 2) - bullet_origin.y) / time_travel

	bullet.speed = Vector2(bullet_vel_x, bullet_vel_y).length()
	bullet.direction = Vector2(bullet_vel_x, bullet_vel_y).normalized()

	w.middle.add_child(bullet)


func exit_shoot(next_state):
	$ShootDelay.stop()

### SIGNALS ###
func _on_PlayerDetector_body_entered(body):
	change_state("shoot")

func _on_PlayerDetector_body_exited(_body):
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
