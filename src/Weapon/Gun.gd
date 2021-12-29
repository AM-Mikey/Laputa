extends Node2D
class_name Gun





export var texture: StreamTexture
export var icon_texture: StreamTexture
export var audio_stream: AudioStream

export var bullet_scene: PackedScene

export var damage: int = 1
export var projectile_range: int = 60
export var projectile_speed: int = 200

export var cooldown_time: float = 0.2
export var automatic: bool = false

export var ammo: int = 0
export var max_ammo: int = 0

export var xp: int = 0
export var max_xp: int = 20
export var level: int = 1
export var max_level: int = 1


var trigger_held = false

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Recruit")
onready var cd = pc.get_node("WeaponManager/CooldownTimer")


func _input(event):
	if not pc.disabled:
		if event.is_action_pressed("fire_manual"):
			fire("manual")
		if event.is_action_pressed("fire_automatic") and automatic:
			fire("automatic")
		if event.is_action_just_released("fire_manual") or event.is_action_just_released("fire_automatic"):
			release_fire()

func fire(type):
	if cd.time_left == 0:
		if type == "manual" and trigger_held: #require a new trigger press
			pass
		trigger_held = true
		cd.start(cooldown_time)
		if max_ammo == 0:
			activate()
		else:
			if ammo == 0:
				print("out of ammo")
				am.play("click")
			else:
				ammo -= 1
				pc.emit_signal("weapons_updated", pc.weapon_array)
				activate()

func release_fire():
	trigger_held = false


func activate():
	pass


func spawn_bullet(bullet_pos, shoot_dir):
	var bullet = bullet_scene.instance()
	
	bullet.damage = damage
	bullet.projectile_range = projectile_range
	bullet.projectile_speed = projectile_speed
	bullet.position = bullet_pos
	bullet.origin = bullet_pos
	bullet.direction = shoot_dir
	
	world.get_node("Middle").add_child(bullet)
	am.play(audio_stream)
	
	var muzzle_flash = load("res://src/Effect/MuzzleFlashEffect.tscn").instance()
	muzzle_flash.position = pc.get_node("WeaponSprite/MuzzlePos").position
	pc.get_node("WeaponSprite").add_child(muzzle_flash)
	
	
	
#func get_bullet_dir(bullet_rot) -> Vector2:
#	if bullet_rot == 90: #Left
#		return Vector2(-1, 0)
#	elif bullet_rot == 270 or bullet_rot == -90: #Right
#		return Vector2(1, 0)
#	elif bullet_rot == 180: #Up
#		return Vector2(0, -1)
#	elif bullet_rot == 0: #Down
#		return Vector2(0, 1)
#	else:
#		printerr("ERROR: Cant get bullet direction!")
#		return Vector2.ZERO
