extends Gun


func _ready():
	display_name = "Shotgun"
	description = "Fires a cluster of birdshot. Get close for max effect."
	icon_texture = load("res://assets/Gun/Blunderbuss.png") #need
	icon_small_texture = load("res://assets/Gun/Blunderbuss.png") #need
	sfx = "gun_shotgun"
	bullet_scene = load("res://src/Bullet/Birdshot.tscn")
	damage = 1
	f_range = 0
	cooldown_time = 1.0
	automatic = false
	do_muzzle_flash = false
	spread_degrees = 36.0
	max_ammo = 0
	max_level = 3
	_set_level(level)

func _set_level(val: int) -> void:
	match val:
		1:
			bullets_per_activate = 4
			speed = 512
			max_xp = 10
		2:
			bullets_per_activate = 8
			speed = 640
			max_xp = 15
		3:
			bullets_per_activate = 16
			speed = 748
			max_xp = 20

func activate():
	for i in bullets_per_activate:
		var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
		bullet.instant_fizzle_check()
