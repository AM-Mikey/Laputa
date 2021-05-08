extends Node
#class_name Weapon, "res://assets/Icon/WeaponIcon.png"

const EFFECT = preload("res://src/Effect/Effect.tscn")

var weapon

var trigger_held = false

onready var HUD = get_tree().get_root().get_node("World/UILayer/HUD")
onready var player = get_tree().get_root().get_node("World/Recruit")

signal ammo_updated(needs_ammo, ammo, max_ammo)
signal weapon_updated(icon_texture, level, xp, max_xp)




func _ready():
	weapon = player.weapon_array[0]
	
	connect("ammo_updated", HUD, "_on_ammo_updated")
	connect("weapon_updated", HUD, "_on_weapon_updated")
	
func update_weapon():
	weapon = player.weapon_array[0]
	player.get_node("WeaponSprite").texture = weapon.texture
	emit_signal("ammo_updated", weapon.needs_ammo, weapon.ammo, weapon.max_ammo)
	emit_signal("weapon_updated", weapon.icon_texture, weapon.level, weapon.xp, weapon.max_xp)

func manual_fire(bullet_pos, effect_pos, bullet_rot): #treats autos and manuals like manual
	var cd = get_node("CooldownTimer")
	if cd.time_left == 0:
		cd.start(weapon.cooldown_time)
		
		if trigger_held == false: #check to see this is a new press
			if weapon.needs_ammo:
				if weapon.ammo == 0:
						print("out of ammo")
				else: #not ammo == 0
					weapon.ammo -= 1
					emit_signal("ammo_updated", weapon.needs_ammo, weapon.ammo, weapon.max_ammo)
					prepare_bullet(bullet_pos, effect_pos, bullet_rot)
			else: #not needs_ammo
				prepare_bullet(bullet_pos, effect_pos, bullet_rot)
			trigger_held = true
	
func automatic_fire(bullet_pos, effect_pos, bullet_rot): #only fires autos but holds direction either way
	var cd = get_node("CooldownTimer")
	if cd.time_left == 0:
		cd.start(weapon.cooldown_time)
	
		if weapon.automatic:
			if weapon.needs_ammo:
				if weapon.ammo == 0:
						print("out of ammo")
				else: #not ammo == 0
					weapon.ammo -= 1
					emit_signal("ammo_updated", weapon.needs_ammo, weapon.ammo, weapon.max_ammo)
					prepare_bullet(bullet_pos, effect_pos, bullet_rot)
			else: #not needs_ammo
				prepare_bullet(bullet_pos, effect_pos, bullet_rot)

func release_fire():
	trigger_held = false

func prepare_bullet(bullet_pos, effect_pos, bullet_rot):
	var bullet = weapon.bullet_scene.instance()
	
	bullet.damage = weapon.damage
	bullet.projectile_range = weapon.projectile_range
	bullet.projectile_speed = weapon.projectile_speed
	
	bullet.position = bullet_pos
	bullet.origin = bullet_pos
	bullet.direction = get_bullet_dir(bullet_rot)
	bullet.rotation_degrees = bullet_rot
	
	get_tree().get_current_scene().add_child(bullet)
	
	var effect = EFFECT.instance()
	get_parent().add_child(effect)
	effect.position = effect_pos 
	var anim = effect.get_node("AnimationPlayer")
	anim.play("StarPop")
	var audio = effect.get_node("AudioStreamPlayer")
	audio.stream = weapon.audio_stream
	audio.play()
	yield(anim, "animation_finished")
	effect.queue_free()
	
func get_bullet_dir(bullet_rot) -> Vector2:
	if bullet_rot == 90: #Left
		return Vector2(-1, 0)
	elif bullet_rot == 270: #Right
		return Vector2(1, 0)
	elif bullet_rot == 180: #Up
		return Vector2(0, -1)
	elif bullet_rot == 0: #Down
		return Vector2(0, 1)
	else:
		return Vector2.ZERO
		print ("ERROR: Cant get bullet direction!")
