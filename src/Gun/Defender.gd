extends Gun

func _ready():
	display_name = "Defender"
	description = "debug, shoot in front and behind"
	texture = load("res://assets/Gun/Revolver.png")
	icon_texture = load("res://assets/Gun/RevolverIcon.png")
	sfx = "gun_pistol"
	bullet_scene = load("res://src/Bullet/BulletRevolver1.tscn")
	damage = 1
	f_range = 60
	speed = 256
	cooldown_time = 0.2
	automatic = false
	max_ammo = 0
	max_xp = 10
	max_level = 1


func activate():
	var origin = pc.get_node("BulletOrigin").global_position
	spawn_bullet(origin, Vector2.LEFT)
	spawn_bullet(origin, Vector2.RIGHT)
