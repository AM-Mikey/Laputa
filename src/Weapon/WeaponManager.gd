extends Node

var sfx_click = load("res://assets/SFX/Placeholder/snd_gun_click.ogg")
var sfx_switch_weapon =  load("res://assets/SFX/Placeholder/snd_switchweapon.ogg")

var weapon

var trigger_held = false

onready var HUD = get_tree().get_root().get_node("World/UILayer/HUD")
onready var pc = get_tree().get_root().get_node("World/Recruit")




func _ready():
	weapon = pc.weapon_array.front()
	
#	connect("ammo_updated", HUD, "update_ammo") #these signals aren't even defined?
#	connect("weapon_updated", HUD, "update_weapon")
	
	
	
	
	
	
	#stuff moved from rectuit.gd
func _physics_process(_delta):
	var bullet_pos = pc.get_node("BulletOrigin").global_position
	var effect_pos = pc.get_node("WeaponSprite").position
	
	if not pc.disabled:
		if Input.is_action_pressed("fire_manual"):
			manual_fire(bullet_pos, effect_pos, pc.shoot_dir)
		if Input.is_action_pressed("fire_automatic"):
			automatic_fire(bullet_pos, effect_pos, pc.shoot_dir)
			
		if Input.is_action_just_released("fire_manual"):
			release_fire()
		if Input.is_action_just_released("fire_automatic"): 
			release_fire()

	
func _input(event):
	if not pc.disabled:
		if pc.weapon_array.size() > 1: #only swap if more than one weapon
			if event.is_action_pressed("weapon_left"):
				shift_weapon("left")
				update_weapon()

			if event.is_action_pressed("weapon_right"):
				shift_weapon("right")
				update_weapon()


	
	
func shift_weapon(direction):
	match direction:
		"left":
			var weapon_to_move = pc.weapon_array.pop_back()
			pc.weapon_array.push_front(weapon_to_move)
		"right":
			var weapon_to_move = pc.weapon_array.pop_front()
			pc.weapon_array.push_back(weapon_to_move)
	$WeaponAudio.stream = sfx_switch_weapon
	$WeaponAudio.play()
	
	
	
	
	
	
	
	
	
	
	
	
func update_weapon():
	weapon = pc.weapon_array.front()
	if weapon != null:
		pc.get_node("WeaponSprite").texture = weapon.texture
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
						$WeaponAudio.stream = sfx_click
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
						$WeaponAudio.stream = sfx_click
						$WeaponAudio.play()
				else:
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
	muzzle_flash.position = get_parent().get_node("WeaponSprite/MuzzlePos").position
	get_parent().get_node("WeaponSprite").add_child(muzzle_flash)
		
	
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
