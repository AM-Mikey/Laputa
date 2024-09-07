@icon("res://assets/Icon/GunIcon.png")
extends Node2D
class_name Gun

const MUZZLE_FLASH = preload("res://src/Effect/MuzzleFlashEffect.tscn")



var display_name: String = "Debug Gun"
var description: String = "Debug Description"

var texture: CompressedTexture2D = load("res://assets/Gun/Revolver.png") #unused
var icon_texture: CompressedTexture2D = load("res://assets/Gun/RevolverIcon.png")
var sfx: String = "gun_pistol"
var bullet_scene: PackedScene = load("res://src/Bullet/BulletRevolver1.tscn")

var damage: int = 1
var f_range: int = 60
var f_time: float
var speed: int = 200

var cooldown_time: float = 0.2
var automatic: bool = false
var do_muzzle_flash: bool = true
var charging: bool = false
var ammo: int = 0
var max_ammo: int = 0

var xp: int = 0
var max_xp: int = 20
var max_level: int = 1
@export var level: int = 1


var trigger_held = false

@onready var world = get_tree().get_root().get_node("World")
@onready var pc = get_parent().get_parent().get_parent()
@onready var cd = pc.get_node("GunManager/CooldownTimer")




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

		if not charging:
			cd.start(cooldown_time)
		
		if type == "automatic":
			await cd.timeout
			if trigger_held:
				fire("automatic")


func release_manual_fire():
	trigger_held = false
	if charging:
		cd.start(cooldown_time)
	deactivate_manual()
	
func release_auto_fire():
	trigger_held = false
	deactivate_auto()


func activate():
	pass
func deactivate_manual():
	pass
func deactivate_auto():
	pass

func spawn_bullet(bullet_pos, shoot_dir, layer = world.get_node("Middle")) -> Node:
	var bullet = bullet_scene.instantiate()
	
	bullet.damage = damage
	bullet.f_range = f_range
	bullet.f_time = f_time
	bullet.speed = speed
	bullet.direction = shoot_dir
	layer.add_child(bullet)
	bullet.global_position = bullet_pos
	bullet.origin = bullet_pos

	am.play(sfx)
	
	if do_muzzle_flash:
		var muzzle_flash = MUZZLE_FLASH.instantiate()
		$Muzzle.add_child(muzzle_flash)
	return bullet

### GETTERS

func get_origin() -> Vector2: #bullet comes from origin, aligned with the muzzle position
	var bullet_origin = pc.get_node("BulletOrigin").global_position
	var out = $Muzzle.global_position
	
	if pc.shoot_dir.x != 0.0: #left or right
		out.x = bullet_origin.x
	elif pc.shoot_dir.y != 0.0: #up or down
		out.y = bullet_origin.y
	return out
