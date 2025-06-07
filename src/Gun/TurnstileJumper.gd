extends Gun

var duration: float
var max_length: float
var max_time: float

func _ready():
	display_name = "Turnstile Jumper"
	description = "A powerful pistol once wielded by a lone cowboy."
	icon_texture = load("res://assets/Gun/TurnstileJumperIcon.png")
	icon_small_texture = load("res://assets/Gun/TurnstileJumperIconSmall.png")
	sfx = "gun_revolver"
	automatic = false
	charging = true
	max_ammo = 0
	max_level = 3
	load_level()

func load_level():
	match level:
		1:
			bullet_scene = load("res://src/Bullet/Laser1.tscn")
			damage = 1
			f_range = 100000000
			speed = 0
			max_xp = 10
			cooldown_time = 0.4
			
			duration = 0.1
			max_length = 128
			max_time = 2.0
		2:
			bullet_scene = load("res://src/Bullet/TurnstileJumper2.tscn")
			damage = 4
			f_range = 150
			speed = 320
			max_xp = 15
			cooldown_time = 0.6
		3:
			bullet_scene = load("res://src/Bullet/TurnstileJumper3.tscn")
			damage = 6
			f_range = 200
			speed = 384
			max_xp = 20
			cooldown_time = 1.0

func activate():
	$ChargeTimer.start(max_time)
	#print("start_charge", max_time)
	

func deactivate_manual():
	var origin = pc.get_node("BulletOrigin").global_position
	var bullet = spawn_bullet(origin, pc.shoot_dir)
	bullet.length = ((max_time - $ChargeTimer.time_left) / max_time) * max_length
	bullet.update_length()
	bullet.get_node("Timer").start(duration)
