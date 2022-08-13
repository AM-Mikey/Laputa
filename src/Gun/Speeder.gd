extends Gun

func _ready():
	display_name = "Speeder"
	description = "A swift weapon that shoots stars."
	texture = load("res://assets/Gun/Speeder.png")
	icon_texture = load("res://assets/Gun/SpeederIcon.png")
	sfx = "gun_pistol"
	cooldown_time = 0.2
	automatic = false
	max_ammo = 0
	max_level = 3
	load_level()

func load_level():
	match level:
		1:
			bullet_scene = load("res://src/Bullet/Star1.tscn")
#			f_range = 60
			speed = 120
			max_xp = 10
		2:
			bullet_scene = load("res://src/Bullet/BulletRevolver2.tscn")
			damage = 2
#			f_range = 96
			speed = 320
			max_xp = 15
		3:
			bullet_scene = load("res://src/Bullet/BulletRevolver3.tscn")
			damage = 4
#			f_range = 128
			speed = 384
			max_xp = 20

func activate():
	var origin = pc.get_node("BulletOrigin").global_position
	spawn_bullet(origin, pc.shoot_dir)
