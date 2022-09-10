extends Node2D
class_name Gun, "res://assets/Icon/GunIcon.png"

const MUZZLE_FLASH = preload("res://src/Effect/MuzzleFlashEffect.tscn")



var display_name: String = "Debug Gun"
var description: String = "Debug Description"

var texture: StreamTexture = load("res://assets/Gun/Revolver.png")
var icon_texture: StreamTexture = load("res://assets/Gun/RevolverIcon.png")
var sfx: String = "gun_pistol"
var bullet_scene: PackedScene = load("res://src/Bullet/BulletRevolver1.tscn")

var damage: int = 1
var f_range: int = 60
var speed: int = 200

var cooldown_time: float = 0.2
var automatic: bool = false
var ammo: int = 0
var max_ammo: int = 0

var xp: int = 0
var max_xp: int = 20
var max_level: int = 1
export var level: int = 1


var trigger_held = false

onready var world = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node("World/Juniper")
onready var cd = pc.get_node("GunManager/CooldownTimer")




func fire(type):
	trigger_held = true
	
	if cd.time_left == 0:
		if max_ammo == 0 or ammo != 0:
			if max_ammo != 0:
				ammo -= 1
			pc.emit_signal("guns_updated", pc.get_node("GunManager/Guns").get_children())
			activate()
		else:
			print("out of ammo")
			am.play("click")

		cd.start(cooldown_time)
		
		if type == "automatic":
			yield(cd, "timeout")
			if trigger_held:
				fire("automatic")


func release_fire():
	trigger_held = false

func activate():
	pass


func spawn_bullet(bullet_pos, shoot_dir):
	var bullet = bullet_scene.instance()
	
	bullet.damage = damage
	bullet.f_range = f_range
	bullet.speed = speed
	bullet.position = bullet_pos
	bullet.origin = bullet_pos
	bullet.direction = shoot_dir
	
	world.get_node("Middle").add_child(bullet)
	am.play(sfx)
	
	var muzzle_flash = MUZZLE_FLASH.instance()
	#muzzle_flash.position = pc.get_node("GunSprite/MuzzlePos").global_position
	$Muzzle.add_child(muzzle_flash)
	
	
	
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
