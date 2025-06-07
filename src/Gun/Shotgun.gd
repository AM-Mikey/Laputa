extends Gun

func _ready():
	display_name = "Shotgun"
	description = "INDEV, shoot in a cone at instant speed"
	icon_texture = load("res://assets/Gun/Blunderbuss.png") #need
	icon_small_texture = load("res://assets/Gun/Blunderbuss.png") #need
	sfx = "gun_shotgun"
	bullet_scene = load("res://src/Bullet/Buckshot.tscn")
	damage = 3
	f_range = 0
	speed = 0
	cooldown_time = 1.0
	automatic = false
	do_muzzle_flash = false
	max_ammo = 0
	max_xp = 0
	max_level = 1

func activate():
	spawn_bullet($Muzzle.global_position, pc.shoot_dir, pc)
