extends Gun

func _ready():
	display_name = "Grenade Launcher"
	description = "Packs a punch."
	texture = load("res://assets/Gun/GLauncher.png")
	icon_texture = load("res://assets/Gun/GLauncherIcon.png")
	sfx = "gun_grenade"
	automatic = false
	ammo = 10
	max_level = 3
	load_level()

func load_level():
	match level:
		1:
			bullet_scene = load("res://src/Bullet/GLauncher1.tscn")
			damage = 4
			speed = 200
			cooldown_time = 1
			max_ammo = 10
			max_xp = 20
		2:
			bullet_scene = load("res://src/Bullet/GLauncher2.tscn")
			damage = 4
			speed = 200
			cooldown_time = 0.5
			max_ammo = 15
			max_xp = 20
		3:
			bullet_scene = load("res://src/Bullet/GLauncher3.tscn")
			damage = 6
			speed = 200
			cooldown_time = 0.5
			max_ammo = 20
			max_xp = 20

func activate():
	var origin = pc.get_node("BulletOrigin").global_position
	spawn_bullet(origin, pc.shoot_dir)
