extends Gun

func _ready():
	display_name = "Tsurugi"
	description = "An ancient sword that deals heavy blows and short range."
	texture = load("res://assets/Gun/Tsurugi.png")
	icon_texture = load("res://assets/Gun/TsurugiIcon.png")
	sfx = "gun_sword"
	cooldown_time = 0.2
	automatic = false
	do_muzzle_flash = false
	max_ammo = 0
	max_level = 1
	load_level()

func load_level():
	match level:
		1:
			bullet_scene = load("res://src/Bullet/Slash.tscn")
			speed = 120
			damage = 4
			max_xp = 0
			f_time = 1.2

func activate():
	var origin = pc.get_node("BulletOrigin").global_position
	var bullet = spawn_bullet(origin, pc.shoot_dir, pc)
