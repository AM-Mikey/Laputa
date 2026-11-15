extends Gun

func _ready():
	description = "A swift and powerful automatic weapon. It runs out of ammo rather quickly."
	icon_texture = load("res://assets/Gun/MPistolM2Icon.png")
	icon_small_texture = load("res://assets/Gun/MPistolM2IconSmall.png")

	sfx = "gun_pistol"
	bullet_scene = load("res://src/Bullet/MPistol.tscn")
	automatic = true
	ammo = 60
	rebuild_count = 1
	max_level = 3
	set_level(level)

func _set_level(val: int) -> void:
	match val:
		1:
			damage = 1
			f_range = 160
			speed = 450
			cooldown_time = 0.2
			recoil = 8
			knockback_strength = 20
			max_ammo = 60
			max_xp = 20
		2:
			damage = 1
			f_range = 180
			speed = 450
			cooldown_time = 0.15
			recoil = 8
			knockback_strength = 20
			max_ammo = 80
			max_xp = 20
		3:
			damage = 2
			f_range = 200
			speed = 450
			cooldown_time = 0.15
			recoil = 8
			knockback_strength = 20
			max_ammo = 100
			max_xp = 10

func activate():
	var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
	bullet.instant_fizzle_check()
