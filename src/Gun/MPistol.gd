extends Gun

var manual_shooting: = false
var manual_cooldown_time: = 0.2
var manual_burst_shot: = 3
var manual_burst_gap: = 0.1

func _ready():
	description = "A swift and powerful automatic weapon. It runs out of ammo rather quickly."
	icon_texture = load("res://assets/Gun/MPistolIcon.png")
	icon_small_texture = load("res://assets/Gun/MPistolIconSmall.png")

	sfx = "gun_pistol"
	bullet_scene = load("res://src/Bullet/MPistol.tscn")
	automatic = true
	ammo = 30
	xp_to_rebuild = 10 #TODO: for debug this is 10, edit this later
	max_level = 3
	xp_loss_multiplier = 20
	set_level(level)

func _set_level(val: int) -> void:
	match val:
		1:
			damage = 1
			f_range = 150
			speed = 400
			cooldown_time = 0.2
			recoil = 6
			knockback_strength = 16
			max_ammo = 40
			max_xp = 20
			manual_cooldown_time = 0.8
			manual_burst_gap = 0.1
			manual_burst_shot = 3
		2:
			damage = 1
			f_range = 150
			speed = 400
			cooldown_time = 0.15
			recoil = 6
			knockback_strength = 16
			max_ammo = 75
			max_xp = 20
			manual_cooldown_time = 0.7
			manual_burst_gap = 0.07
			manual_burst_shot = 3
		3:
			damage = 1
			speed = 500
			cooldown_time = 0.1
			recoil = 6
			knockback_strength = 16
			max_ammo = 100
			max_xp = 10
			manual_cooldown_time = 0.5
			manual_burst_gap = 0.05
			manual_burst_shot = 4

func fire(type):
	if type == "automatic":
		if !manual_shooting && cd.time_left <= 0.0 && $ManualTimer.time_left <= 0.0:
			if max_ammo == 0 || ammo != 0:
				if max_ammo != 0:
					ammo -= 1
				pc.emit_signal("guns_updated", pc.get_node("GunManager/Guns").get_children(), "fire")
				am.play(sfx)
				pc.velocity += (pc.shoot_dir * -1) * recoil
				activate()
			else:
				print("out of ammo")
				am.play("click")

			cd.start(cooldown_time)
	if type == "manual":
		if $ManualTimer.time_left <= 0.0:
			manual_shooting = true
			for i in range(0, manual_burst_shot):
				if max_ammo == 0 || ammo != 0:
					if i == 0:
						$ManualTimer.start(manual_cooldown_time)
					if max_ammo != 0:
						ammo -= 1
					pc.emit_signal("guns_updated", pc.get_node("GunManager/Guns").get_children(), "fire")
					am.play(sfx)
					pc.velocity += (pc.shoot_dir * -1) * recoil
					activate()
					await get_tree().create_timer(manual_burst_gap).timeout
				else:
					print("out of ammo")
					am.play("click")
			manual_shooting = false


func activate():
	var bullet = spawn_bullet(get_origin(), pc.shoot_dir)
	bullet.instant_fizzle_check()
