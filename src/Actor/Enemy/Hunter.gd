extends Enemy

export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2

const BULLET = preload("res://src/Bullet/Enemy/Laser.tscn")
export var projectile_speed: int = 200
export var bullet_height_adjustment = 1
export var cooldown_time = 4.0
export var bullet_damage = 4

var target: Node = null
var locked_on = false
var shooting = false

var walk_time = 1


func _ready():
	rng.randomize()
	hp = 20
	damage_on_contact = 1
	speed = Vector2(80, 100)
	gravity = 250
	
	reward = 4
	
	$FireCooldown.start(cooldown_time)
	
	#wander()

func _physics_process(_delta):
	if disabled or dead:
		return
	if is_on_wall():
		if not locked_on:
				move_dir.x *= -1


	velocity = calculate_movevelocity(velocity, move_dir, speed)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	
	animate()

func calculate_movevelocity(velocity: Vector2, move_dir, speed) -> Vector2:
	var out: = velocity
	
	out.x = speed.x * move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y

	return out
	
func _on_PlayerDetector_body_entered(body):
	if not locked_on:
		target = body
		locked_on = true
		fire()
		
func _on_PlayerDetector_body_exited(_body):
	locked_on = false
	search()
	
func wander():
	shooting = false
	while target == null:
		var dir = Vector2(sign(rng.randf_range(-1,1)), 0)
		move_dir = dir
		look_dir = dir
		
		yield(get_tree().create_timer(walk_time), "timeout")
		move_dir = Vector2.ZERO
		if look_dir == Vector2.LEFT:
			$AnimationPlayer.play("BlinkLeft")
		elif look_dir == Vector2.RIGHT:
			$AnimationPlayer.play("BlinkRight")
		yield($AnimationPlayer, "animation_finished")

func fire():
	if not shooting:
		shooting = true
		if $FireCooldown.is_stopped():
			while locked_on:
				$FireCooldown.start(cooldown_time)
				if target.global_position < global_position: #player to the left
					$AnimationPlayer.play("ShootLeft")
					look_dir = Vector2.LEFT
				elif target.global_position > global_position: #player to the right
					$AnimationPlayer.play("ShootRight")
					look_dir = Vector2.RIGHT
				yield(get_tree().create_timer(0.2), "timeout") #delay for animation sync
				if not locked_on:
					break
				prepare_bullet()
				yield($FireCooldown, "timeout")
				if not locked_on:
					break
		else: 
			yield($FireCooldown, "timeout")
			fire()

func search():
	shooting = false
	while not locked_on:
		var dir = Vector2(sign(target.global_position.x - global_position.x), 0)
		move_dir = dir
		look_dir = dir
		
		yield(get_tree().create_timer(walk_time), "timeout")
		move_dir = Vector2.ZERO
		if look_dir == Vector2.LEFT:
			$AnimationPlayer.play("SniffLeft")
		elif look_dir == Vector2.RIGHT:
			$AnimationPlayer.play("SniffRight")
		yield($AnimationPlayer, "animation_finished")
	

func prepare_bullet():
	#print("hunter fired bullet")
	var bullet = BULLET.instance()
	get_tree().get_current_scene().add_child(bullet)
	
	bullet.position = Vector2($CollisionShape2D.global_position.x, $CollisionShape2D.global_position.y + bullet_height_adjustment)
	bullet.direction = look_dir
	bullet.origin = global_position
	if look_dir == Vector2.LEFT:
		bullet.rotation_degrees = 0
	if look_dir == Vector2.RIGHT:
		bullet.rotation_degrees = 180
	bullet.damage = bullet_damage
	fire_bullet(bullet)
	$PosFire.play()

func fire_bullet(bullet):
	bullet.velocity.x = projectile_speed * get_physics_process_delta_time() * sign(bullet.direction.x)
	bullet.velocity.y = projectile_speed * get_physics_process_delta_time() * sign(bullet.direction.y)


func animate():
	if move_dir == Vector2.LEFT:
		$AnimationPlayer.play("WalkLeft")
	elif move_dir == Vector2.RIGHT:
		$AnimationPlayer.play("WalkRight")
