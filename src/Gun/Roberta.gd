extends Gun

@export var recoil_curve : Curve

func _ready():
	display_name = "Roberta"
	description = "Provides reliable rapid fire. Its large ammo capacity is stored in its stock."
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
			recoil = 12
			max_ammo = 200
			max_xp = 20
		2:

			damage = 1
			f_range = 150
			speed = 400
			cooldown_time = 0.15
			recoil = 12
			max_ammo = 250
			max_xp = 20
		3:
			damage = 2
			speed = 400
			cooldown_time = 0.15
			recoil = 12 #NOTE: this level of recoil allows jp to reach up +1 and over +0, don't allow more than this.
			max_ammo = 250
			max_xp = 10

func activate():
	#if f.pc(): #and camera gun recoil is true
		#f.pc().get_node("PlayerCamera").impulse(pc.shoot_dir * -1, 1.5, 0.1, recoil_curve)
	var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
	bullet.instant_fizzle_check()
