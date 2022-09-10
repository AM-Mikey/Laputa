extends Gun

func _ready():
	display_name = "Shotgun"
	description = "debug, shoot in a rectangular area at instant speed"
	texture = load("res://assets/Gun/Blunderbuss.png")
	icon_texture = load("res://assets/Gun/Blunderbuss.png")
	sfx = "gun_shotgun"
	bullet_scene = load("res://src/Bullet/BulletShotgun1.tscn")
	damage = 3
	f_range = 0
	speed = 0
	cooldown_time = 0.5
	automatic = false
	max_ammo = 0
	max_xp = 10
	max_level = 1

func activate():
	spawn_bullet($Muzzle.global_position, pc.shoot_dir)
