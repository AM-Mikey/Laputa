extends Enemy

export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2

const HAIRBALL = preload("res://src/Bullet/Enemy/Hairball.tscn")

export var height_tolerance = 7
export var cooldown_time = 1
export var projectile_speed: int = 150
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
	
	level = 1
	
	$FireCooldown.start(cooldown_time)
	

func _physics_process(delta):
	
	if locked_on:
		distance_lock()
		if move_dir.x == 0: #in position to hit
			fire()
	else:
		move_dir.x = 0
	


#	animate()

	


func _on_PlayerDetector_body_entered(body):
	target = body
	locked_on = true

func _on_PlayerDetector_body_exited(body):
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
						
					$AnimationPlayer.play("ShootLeft")
					yield(get_tree().create_timer(0.2), "timeout") #delay for animation sync
					if target == null:
						break
					prepare_bullet()
					yield($FireCooldown, "timeout")
			else: 
				yield($FireCooldown, "timeout")
				fire()

func prepare_bullet():
	var bullet = HAIRBALL.instance()
	bullet.damage = projectile_damage
	bullet.projectile_speed = projectile_speed
	
	bullet.position = Vector2($CollisionShape2D.global_position.x, $CollisionShape2D.global_position.y - height_tolerance)
	bullet.direction = Vector2(look_dir.x /2 , -1) #Adjust this for angle
	
	get_tree().get_current_scene().add_child(bullet)


	$PosFire.play()




#func animate():
#	if look_dir == Vector2.LEFT:
#		if locked_on:
#			if move_dir.x != 0:
#				$BodyPlayer.play("WalkLeft")
#			else:
#				$BodyPlayer.play("StandLeft")
#		else:
#			if is_on_floor():
#				$BodyPlayer.play("StandLeft")
##			else:
##				if move_dir.y < 0:
##					$BodyPlayer.play("RiseLeft")
##				elif move_dir.y > 0:
##					$BodyPlayer.play("FallLeft")
#
#	if look_dir == Vector2.RIGHT:
#		if locked_on:
#			if move_dir.x != 0:
#				$BodyPlayer.play("WalkRight")
#			else:
#				$BodyPlayer.play("StandRight")
#		else:
#			if is_on_floor():
#				$BodyPlayer.play("StandRight")
##			else:
##				if move_dir.y < 0:
##					$BodyPlayer.play("RiseRight")
##				elif move_dir.y > 0:
##					$BodyPlayer.play("FallRight")





