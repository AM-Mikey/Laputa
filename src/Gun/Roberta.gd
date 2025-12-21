extends Gun

func _ready():
	display_name = "Roberta"
	description = "A swift and powerful SMG. It stores ammo in its stock."
	icon_texture = load("res://assets/Gun/RobertaIcon.png")
	icon_small_texture = load("res://assets/Gun/RobertaIconSmall.png")

	sfx = "gun_pistol"
	bullet_scene = load("res://src/Bullet/MPistol.tscn")
	automatic = true
	ammo = 200
	max_level = 3
	set_level(level)

func _set_level(val: int) -> void:
	match val:
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
	var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
	bullet.instant_fizzle_check()
