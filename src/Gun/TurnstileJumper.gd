extends Gun

const GUN_SMOKE = preload("res://src/Effect/GunSmoke.tscn")

#var duration: float
#var max_length: float
#var max_time: float

func _ready():
	display_name = "Turnstile Jumper"
	description = "A powerful revolver once wielded by a lone cowboy."
	icon_texture = load("res://assets/Gun/TurnstileJumperIcon.png")
	icon_small_texture = load("res://assets/Gun/TurnstileJumperIconSmall.png")
	sfx = "gun_turnstile_jumper"
	automatic = false
	#charging = true
	max_ammo = 0
	max_level = 3
	set_level(level)

func _set_level(val: int) -> void:
	match val:
		1:
			bullet_scene = load("res://src/Bullet/TurnstileJumper1.tscn")
			damage = 1
			f_range = 128
			speed = 256
			max_xp = 10
			cooldown_time = 0.4
			recoil = 10
		2:
			bullet_scene = load("res://src/Bullet/TurnstileJumper2.tscn")
			damage = 4
			f_range = 192
			speed = 384
			max_xp = 15
			cooldown_time = 0.6
			recoil = 20
		3:
			bullet_scene = load("res://src/Bullet/TurnstileJumper3.tscn")
			damage = 6
			f_range = 256
			speed = 512
			max_xp = 20
			cooldown_time = 1.0
			recoil = 30 #NOTE: this level of recoil allows jp to reach up +1 and over +0, don't allow more than this.

func activate():
	var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
	bullet.instant_fizzle_check()
	var gun_smoke = GUN_SMOKE.instantiate()
	gun_smoke.direction = Vector2(pc.shoot_dir.x, 0)
	gun_smoke.global_position = $Muzzle.global_position
	w.middle.add_child(gun_smoke)

#old code for charging varient
#func activate():
	#$ChargeTimer.start(max_time)
	##print("start_charge", max_time)
#
#
#func deactivate_manual():
	#var origin = pc.get_node("BulletOrigin").global_position
	#var bullet = spawn_bullet(origin, pc.shoot_dir)
	#bullet.length = ((max_time - $ChargeTimer.time_left) / max_time) * max_length
	#bullet.update_length()
	#bullet.get_node("Timer").start(duration)
