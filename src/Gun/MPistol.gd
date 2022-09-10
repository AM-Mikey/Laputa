extends Gun

func _ready():
	display_name = "Machine Pistol"
	description = "A swift and powerful automatic weapon. It runs out of ammo rather quickly."
	texture = load("res://assets/Gun/MPistol.png")
	icon_texture = load("res://assets/Gun/MPistolIcon.png")
	sfx = "gun_pistol"
	bullet_scene = load("res://src/Bullet/MPistol.tscn")
	automatic = true
	ammo = 200
	max_level = 3
	load_level()

func load_level():
	match level:
		1:
			damage = 1
			f_range = 150
			speed = 400
			cooldown_time = 0.2
			max_ammo = 200
			max_xp = 20
		2:

			damage = 1
			f_range = 150
			speed = 400
			cooldown_time = 0.15
			max_ammo = 250
			max_xp = 20
		3:
			damage = 2
			speed = 400
			cooldown_time = 0.15
			max_ammo = 250
			max_xp = 10

func activate():
	spawn_bullet(get_origin(), pc.shoot_dir)
