extends Enemy

@export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2

const BULLET = preload("res://src/Bullet/EnemyBulletTemplate.tscn")
@export var projectile_speed: int = 120
@export var height_tolerance = 7

var target: Node


func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(100, 200)
	gravity = 250

func _physics_process(delta):
	if not is_on_floor():
		move_dir.y = 0 #don't allow them to jump if they are midair
	if not dead:
		velocity = calculate_movevelocity(velocity, move_dir, speed)
		set_up_direction(FLOOR_NORMAL)
		move_and_slide()

func calculate_movevelocity(velocity: Vector2, move_dir, speed) -> Vector2:
	var out: = velocity
	
	out.x = speed.x * move_dir.x
	out.y += gravity * get_physics_process_delta_time()
	if move_dir.y < 0:
		out.y = speed.y * move_dir.y

	return out
	
func _on_PlayerDetector_body_entered(body):
	if visible == true:
		target = body.owner
		jump()

func jump():
	$PlayerDetector.set_deferred("monitoring", false) #will not be triggered while jumping
	move_dir.y -= 1 #up until leaves ground
	var height_from_target = global_position.y - target.global_position.y
	#print(height_from_target)
	if abs(height_from_target) < height_tolerance and $FireCooldown.time_left == 0: #less than x from target and cooldown finished
		$FireCooldown.start()
		prepare_bullet()
	$PlayerDetector.set_deferred("monitoring", true) #once jump and shoot are finished return to normal

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
	$PosFire.play()

func fire_bullet(bullet):
	bullet.velocity.x = projectile_speed * get_physics_process_delta_time() * sign(bullet.direction.x)
	bullet.velocity.y = projectile_speed * get_physics_process_delta_time() * sign(bullet.direction.y)
