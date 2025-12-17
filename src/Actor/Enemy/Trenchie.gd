extends Enemy

@export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2

const BULLET = preload("res://src/Bullet/Enemy/Laser.tscn")
@export var projectile_speed: int = 120
@export var height_tolerance = 7
@export var cooldown_time = 1
@export var lock_distance = 8

var target: Node = null
var cover_blown = false
var shooting = false
var hiding = false
var peeking = false


func setup():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 200)
	gravity = 250

	reward = 3

	$FireCooldown.start(cooldown_time)

	cover()

func _physics_process(_delta):
	if disabled or dead: return
	if not is_on_floor():
		move_dir.y = 0 #don't allow them to jump if they are midair

	velocity = calc_velocity(move_dir)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	animate()



func _on_HideDetector_body_entered(body):
	if cover_blown:
		fire()
	else:
		target = body
		look_dir = Vector2(sign(target.global_position.x - global_position.x), 0)
		hide()

func _on_PeekDetector_body_entered(body):
	target = body.get_parent()
	look_dir = Vector2(sign(target.global_position.x - global_position.x), 0)
	peek()

func _on_PeekDetector_body_exited(_body):
	shooting = false
	target = null
	hide()

func _on_ShootDetector_body_entered(body):
	target = body.get_parent()
	look_dir = Vector2(sign(target.global_position.x - global_position.x), 0)
	jump()


func peek():
	peeking = true
	hiding = false
	shooting = false

func cover():
	hiding = true
	peeking = false
	shooting = false


func jump():
	cover_blown = true

	move_dir.y -= 1 #up until leaves ground

	fire()


func fire():
	if not shooting:
			shooting = true
			if $FireCooldown.is_stopped():
				while target != null:
					$FireCooldown.start(cooldown_time)
					if target.global_position < global_position: #player to the left
						$AnimationPlayer.play("ShootLeft")
						look_dir = Vector2.LEFT
					elif target.global_position > global_position: #player to the right
						$AnimationPlayer.play("ShootRight")
						look_dir = Vector2.RIGHT
					await get_tree().create_timer(0.2).timeout #delay for animation sync
					if target == null:
						break
					prepare_bullet()
					await $FireCooldown.timeout
			else:
				await $FireCooldown.timeout
				fire()
func prepare_bullet():
	var bullet = BULLET.instantiate()
	get_tree().get_current_scene().add_child(bullet)

	bullet.position = Vector2($CollisionShape2D.global_position.x, $CollisionShape2D.global_position.y - height_tolerance)
	bullet.direction = look_dir
	bullet.origin = global_position
	if look_dir == Vector2.LEFT:
		bullet.rotation_degrees = 0
	if look_dir == Vector2.RIGHT:
		bullet.rotation_degrees = 180
	fire_bullet(bullet)
	am.play("enemy_shoot", self)

func fire_bullet(bullet):
	bullet.velocity.x = projectile_speed * get_physics_process_delta_time() * sign(bullet.direction.x)
	bullet.velocity.y = projectile_speed * get_physics_process_delta_time() * sign(bullet.direction.y)

func animate():
	if look_dir == Vector2.LEFT:
		if not cover_blown:
			if hiding:
				$AnimationPlayer.play("Barrel")
			elif peeking:
				$AnimationPlayer.play("BarrelPeekLeft")
		else:
			if is_on_floor():
				$AnimationPlayer.play("StandLeft")
			else:
				if move_dir.y < 0:
					$AnimationPlayer.play("RiseLeft")
				elif move_dir.y > 0:
					$AnimationPlayer.play("FallLeft")

	if look_dir == Vector2.RIGHT:
		if not cover_blown:
			if hiding:
				$AnimationPlayer.play("Barrel")
			elif peeking:
				$AnimationPlayer.play("BarrelPeekRight")
		else:
			if is_on_floor():
				$AnimationPlayer.play("StandRight")
			else:
				if move_dir.y < 0:
					$AnimationPlayer.play("RiseRight")
				elif move_dir.y > 0:
					$AnimationPlayer.play("FallRight")
