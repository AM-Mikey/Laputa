extends Node

var sound_click = load("res://assets/SFX/snd_gun_click.ogg")

var weapon

var trigger_held = false

onready var HUD = get_tree().get_root().get_node("World/UILayer/HUD")
onready var player = get_tree().get_root().get_node("World/Recruit")



func _ready():
	weapon = player.weapon_array.front()
	
	connect("ammo_updated", HUD, "_on_ammo_updated")
	connect("weapon_updated", HUD, "_on_weapon_updated")
	
func update_weapon():
	weapon = player.weapon_array.front()
	if weapon != null:
		player.get_node("WeaponSprite").texture = weapon.texture
		HUD.update_weapon()

func manual_fire(bullet_pos, effect_pos, shoot_dir): #treats autos and manuals like manual
	if weapon == null:
		return
	
	var cd = get_node("CooldownTimer")
	if cd.time_left == 0:
		if trigger_held == false: #check to see this is a new press
			cd.start(weapon.cooldown_time)
			if weapon.needs_ammo:
				if weapon.ammo == 0:
						print("out of ammo")
						$WeaponAudio.stream = sound_click
						$WeaponAudio.play()
				else: #not ammo == 0
					weapon.ammo -= 1
					HUD.update_ammo()
					prepare_bullet(bullet_pos, effect_pos, shoot_dir)
			else: #not needs_ammo
				prepare_bullet(bullet_pos, effect_pos, shoot_dir)
			trigger_held = true
	
func automatic_fire(bullet_pos, effect_pos, shoot_dir): #only fires autos but holds direction either way
	if weapon == null:
		return
		
	var cd = get_node("CooldownTimer")
	if cd.time_left == 0:
		if weapon.automatic:
			cd.start(weapon.cooldown_time)
			if weapon.needs_ammo:
				if weapon.ammo == 0:
						print("out of ammo")
						$WeaponAudio.stream = sound_click
						$WeaponAudio.play()
				else: #not ammo == 0
					weapon.ammo -= 1
					HUD.update_weapon()
					prepare_bullet(bullet_pos, effect_pos, shoot_dir)
			else: #not needs_ammo
				prepare_bullet(bullet_pos, effect_pos, shoot_dir)

func release_fire():
	trigger_held = false

func prepare_bullet(bullet_pos, effect_pos, shoot_dir):
	var bullet = weapon.bullet_scene.instance()
	
	bullet.damage = weapon.damage
	bullet.projectile_range = weapon.projectile_range
	bullet.projectile_speed = weapon.projectile_speed
	
	bullet.position = bullet_pos
	bullet.origin = bullet_pos
	bullet.direction = shoot_dir
	
	get_tree().get_current_scene().add_child(bullet)
	
	###fire audio
	$WeaponAudio.stream = weapon.audio_stream
	$WeaponAudio.play()
	
	###starpop/muzzle flash
	var muzzle_flash = load("res://src/Effect/MuzzleFlashEffect.tscn").instance()
	muzzle_flash.position = get_parent().get_node("WeaponSprite").position
	get_parent().add_child(muzzle_flash)
		
	
func get_bullet_dir(bullet_rot) -> Vector2:
	if bullet_rot == 90: #Left
		return Vector2(-1, 0)
	elif bullet_rot == 270 or bullet_rot == -90: #Right
		return Vector2(1, 0)
	elif bullet_rot == 180: #Up
		return Vector2(0, -1)
	elif bullet_rot == 0: #Down
		return Vector2(0, 1)
	else:
		return Vector2.ZERO
		printerr("ERROR: Cant get bullet direction!")
