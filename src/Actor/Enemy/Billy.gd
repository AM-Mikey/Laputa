extends Enemy

const SEED = preload("res://src/Bullet/Enemy/Seed.tscn")
const WAYPOINT = preload("res://src/Utility/Waypoint.tscn")

export var move_dir = Vector2.LEFT
export var look_dir = Vector2.LEFT

export var idle_max_time = 5.0
export var walk_max_time = 10.0
export var defend_time = 0.4



export var cooldown_time = 1
export var bullet_speed: int = 200
export var bullet_damage: int = 2


export var lock_distance = 128
export var lock_tolerance = 16

var target: Node
var locked_on = false
var shooting = false

var waypoint

onready var ap = $AnimationPlayer



func setup():
	change_state("walk")
	hp = 6
	reward = 2
	damage_on_contact = 1
	speed = Vector2(50, 50)




### STATES ###

func enter_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		move_dir = Vector2.RIGHT
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		move_dir = Vector2.LEFT
	
	ap.play("Walk")
	
	match move_dir:
		Vector2.LEFT: $Sprite.flip_h = false
		Vector2.RIGHT: $Sprite.flip_h = true
	
	rng.randomize()
	$StateTimer.start(rng.randf_range(1.0, walk_max_time))
	yield($StateTimer, "timeout")
	change_state("idle")

func do_walk():
	if not $FloorDetectorL.is_colliding() and move_dir.x < 0:
		change_state("idle")
	if not $FloorDetectorR.is_colliding() and move_dir.x > 0:
		change_state("idle")
	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
		velocity = get_velocity(velocity, move_dir, speed)
		velocity = move_and_slide(velocity, FLOOR_NORMAL)


func enter_idle():
	rng.randomize()
	ap.play("Idle")
	match move_dir:
		Vector2.LEFT: $Sprite.flip_h = false
		Vector2.RIGHT: $Sprite.flip_h = true
	$StateTimer.start(rng.randf_range(1.0, idle_max_time))
	yield($StateTimer, "timeout")
	change_state("walk")


func enter_aggro():
	pass

func do_aggro():
	if pc: #TODO: global enemy shutdown fix
		var target_dir = Vector2(sign(position.x - pc.position.x), 0)
		look_dir = target_dir * -1
		set_waypoint(target_dir)
	#this isnt the best way to do this, but returns a good result. 
	#right now this cuts off move_dir when it's more than a block away (to -1 or 1)
	#the small adjustment when less than that is why we don't just use sign()
	var x_dir = clamp((waypoint.position.x - position.x)/16, -1, 1) 
	move_dir = Vector2(lerp(move_dir.x, x_dir, 0.2), 0)

	if abs(position.x - waypoint.position.x) < lock_tolerance:
		if abs(move_dir.x) < 0.1:
			ap.play("StandShoot")
		else:
			ap.play("WalkShoot")
	else:
		ap.play("Walk")

#	if $FloorDetectorL.is_colliding() or $FloorDetectorR.is_colliding():
	velocity = get_velocity(velocity, move_dir, speed)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)



### HELPERS ###

func fire():
	var bullet = SEED.instance()
	
	bullet.damage = bullet_damage
	bullet.speed = bullet_speed
	bullet.position = $BulletOrigin.global_position
	bullet.origin = $BulletOrigin.global_position
	bullet.direction = Vector2(look_dir.x /2 , -1) #Adjust this for angle

	world.get_node("Middle").add_child(bullet)
	am.play("enemy_shoot")

func set_waypoint(target_dir: Vector2):
	if waypoint: waypoint.queue_free()
	waypoint = WAYPOINT.instance()
	waypoint.position = Vector2(pc.position.x + (lock_distance * target_dir.x), pc.position.y) #left or right of pc
	waypoint.owner_id = id
	waypoint.index = -1
	world.current_level.add_child(waypoint)

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	$StateTimer.stop()
	change_state("aggro")

func _on_PlayerDetector_body_exited(_body):
	pass
	#shooting = false
	#target = null
	#change_state("walk")
