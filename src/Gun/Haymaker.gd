extends Gun

func _ready(): #since preload, this happens on game start
	display_name = "Haymaker"
	description = "A Weapon That Shoots Sleeping Darts. TODO:finish."
	icon_texture = load("res://assets/Gun/HaymakerIcon.png")
	icon_small_texture = load("res://assets/Gun/HaymakerIconSmall.png")
	
	sfx = "gun_pistol"
	cooldown_time = 0.1
	automatic = false
	max_ammo = 0
	max_level = 3
	load_level()

func load_level():
	match level:
		1:
			bullet_scene = load("res://src/Bullet/BulletRevolver1.tscn")
			f_range = 60
			speed = 256
			max_xp = 10
		2:
			bullet_scene = load("res://src/Bullet/BulletRevolver2.tscn")
			damage = 2
			f_range = 96
			speed = 320
			max_xp = 15
		3:
			bullet_scene = load("res://src/Bullet/BulletRevolver3.tscn")
			damage = 4
			f_range = 128
			speed = 384
			max_xp = 20

func activate():
	var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
	bullet.instant_fizzle_check()
