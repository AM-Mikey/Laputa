extends Enemy

export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2

const SEED = preload("res://src/Bullet/Enemy/Seed.tscn")

export var height_tolerance = 7
export var cooldown_time = 1
export var projectile_speed: int = 200
export var projectile_damage: int = 2


export var lock_distance = 128
export var lock_tolerance = 16

var target: Node = null
var locked_on = false


var shooting = false


func _ready():
	hp = 4
	damage_on_contact = 1
	speed = Vector2(50, 200)
	gravity = 250
	
	$FireCooldown.start(cooldown_time)
	

func _physics_process(_delta):
	
	if locked_on:
		distance_lock()
		if move_dir.x == 0: #in position to hit
			fire()
	else:
		move_dir.x = 0
	
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
	target = body
	locked_on = true

func _on_PlayerDetector_body_exited(_body):
	shooting = false
	target = null
	locked_on = false
	

func distance_lock():
		var lock_pos_x = target.global_position.x
		
		if global_position.x - lock_pos_x > 0: #player to the left
			lock_pos_x += lock_distance
			look_dir = Vector2.LEFT
		elif global_position.x - lock_pos_x < 0: #player to the right
			lock_pos_x -= lock_distance
			look_dir = Vector2.RIGHT
			
		move_dir.x = sign(lock_pos_x - global_position.x)
		
		#print("distance to lock pos: ", lock_pos_x - global_position.x)
		
		if abs(global_position.x - lock_pos_x) < lock_tolerance:
			move_dir.x = 0


#func jump():
#	cover_blown = true
#
#	move_dir.y -= 1 #up until leaves ground
#
#	fire()


func fire():
	if not shooting:
			shooting = true
			if $FireCooldown.is_stopped():
				while target != null:
					$FireCooldown.start(cooldown_time)
					
#					if target.global_position < global_position: #player to the left
#						#look_dir = Vector2.LEFT
#					elif target.global_position > global_position: #player to the right
#						#look_dir = Vector2.RIGHT
						
					$HatPlayer.play("Shoot")
					yield(get_tree().create_timer(0.2), "timeout") #delay for animation sync
					if target == null:
						break
					prepare_bullet()
					yield($FireCooldown, "timeout")
			else: 
				yield($FireCooldown, "timeout")
				fire()

func prepare_bullet():
	var bullet = SEED.instance()
	bullet.damage = projectile_damage
	bullet.projectile_speed = projectile_speed
	bullet.position = Vector2($CollisionShape2D.global_position.x, $CollisionShape2D.global_position.y - height_tolerance)
	bullet.direction = Vector2(look_dir.x /2 , -1) #Adjust this for angle
	
	get_tree().get_current_scene().add_child(bullet)


	$PosFire.play()




func animate():
	if look_dir == Vector2.LEFT:
		if locked_on:
			if move_dir.x != 0:
				$BodyPlayer.play("WalkLeft")
			else:
				$BodyPlayer.play("StandLeft")
		else:
			if is_on_floor():
				$BodyPlayer.play("StandLeft")
#			else:
#				if move_dir.y < 0:
#					$BodyPlayer.play("RiseLeft")
#				elif move_dir.y > 0:
#					$BodyPlayer.play("FallLeft")
				
	if look_dir == Vector2.RIGHT:
		if locked_on:
			if move_dir.x != 0:
				$BodyPlayer.play("WalkRight")
			else:
				$BodyPlayer.play("StandRight")
		else:
			if is_on_floor():
				$BodyPlayer.play("StandRight")
#			else:
#				if move_dir.y < 0:
#					$BodyPlayer.play("RiseRight")
#				elif move_dir.y > 0:
#					$BodyPlayer.play("FallRight")





