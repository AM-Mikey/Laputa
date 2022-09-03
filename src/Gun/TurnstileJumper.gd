extends Gun

func _ready():
	display_name = "Turnstyle Jumper"
	description = "A powerful pistol once wielded by a lone cowboy."
	texture = load("res://assets/Gun/TurnstileJumper.png")
	icon_texture = load("res://assets/Gun/TurnstileJumperIcon.png")
	sfx = "gun_revolver"
	automatic = false
	max_ammo = 0
	max_level = 3
	load_level()

func load_level():
	match level:
		1:
			bullet_scene = load("res://src/Bullet/TurnstileJumper1.tscn")
			damage = 2
			f_range = 100
			speed = 256
			max_xp = 10
			cooldown_time = 0.4
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
	var origin = pc.get_node("BulletOrigin").global_position
	spawn_bullet(origin, pc.shoot_dir)
