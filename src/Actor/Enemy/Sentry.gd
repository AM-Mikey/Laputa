extends Enemy

@export var look_dir: Vector2 = Vector2.LEFT
var move_dir: Vector2

const HAIRBALL = preload("res://src/Bullet/Enemy/Hairball.tscn")

@export var height_tolerance = 7
@export var cooldown_time = 2.0
@export var projectile_speed: int = 150
@export var projectile_damage: int = 2


#@export var shoot_distance = 128
#@export var shoot_tolerance = 16

var target: Node = null
var locked_on = false


var shooting = false


func setup():
	change_state("idle")
	hp = 4
	damage_on_contact = 1
	speed = Vector2(50, 200)
	gravity = 250
	reward = 2


### STATES ###

func enter_target():
	change_state("shoot")

#func enter_target():
	#var target_pos_x = target.global_position.x
	#if global_position.x >= target_pos_x: #player to the left
		#target_pos_x += shoot_distance
		#look_dir = Vector2.LEFT
	#else: #player to the right
		#target_pos_x -= shoot_distance
		#look_dir = Vector2.RIGHT
	#
	#if abs(global_position.x - target_pos_x) < shoot_tolerance:
		#change_state("shoot")

func enter_shoot():
	prepare_bullet()
	$StateTimer.start(cooldown_time)
	
	







func prepare_bullet():
	am.play("enemy_shoot", self)
	var bullet = HAIRBALL.instantiate()
	bullet.damage = projectile_damage
	bullet.speed = projectile_speed
	
	bullet.position = Vector2($CollisionShape2D.global_position.x, $CollisionShape2D.global_position.y - height_tolerance)
	bullet.direction = Vector2(look_dir.x / 2.0, -1) #Adjust this for angle
	
	w.middle.add_child(bullet)



### SIGNALS ###



func _on_PlayerDetector_body_entered(body):
	target = body.owner
	change_state("target")

func _on_PlayerDetector_body_exited(_body):
	target = null
	change_state("idle")

func _on_StateTimer_timeout():
	if state == "shoot":
		change_state("target")
