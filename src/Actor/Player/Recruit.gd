#TODO re-extend to actor once we remove movement from actor.gd
extends KinematicBody2D
class_name Recruit, "res://assets/Icon/PlayerIcon.png"

#const POPUP = preload("res://src/UI/PopupText.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const DEATH_CAMERA = preload("res://src/Utility/DeathCamera.tscn")
const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")


signal hp_updated(hp, max_hp)
signal total_xp_updated(total_xp)
signal guns_updated(guns)


export var hp: int = 8
export var max_hp: int = 8
var total_xp: int = 0


#STATES
var direction_lock = Vector2.ZERO

var invincible = false
var disabled = true
var inspecting = false


#var is_on_conveyor = false
var enemies_touching = []
var is_on_ssp = false
var is_in_water = false
var dead = false


var inventory: Array
var topic_array: Array = ["child", "sasuke", "basil", "free_dialog"]
#var weapon_array: Array = [load("res://src/Weapon/Revolver1.tres"), load("res://src/Weapon/GreaseGun.tres"), load("res://src/Weapon/Defender.tres"), load("res://src/Weapon/GrenadeLauncher1.tres"), load("res://src/Weapon/MachinePistol1.tres"), load("res://src/Weapon/Shotgun1.tres")]


var move_dir = Vector2.LEFT
var face_dir = Vector2.LEFT
var shoot_dir = Vector2.LEFT



onready var world = get_tree().get_root().get_node("World")
onready var HUD
onready var mm = get_node("MovementManager")
onready var gm = get_node("GunManager")
onready var guns = get_node("GunManager/Guns")


func _ready():
	connect_inventory()
#	if weapon_array.front() != null: TODO:fix
#		$WeaponSprite.texture = weapon_array.front().texture
	

func _input(event):
	if not disabled:
		pass
#		if event.is_action_pressed("inspect"):
#			if is_on_floor():
#				inspecting = true
#		if event.is_action_released("inspect"):
#			inspecting = false


func disable():
	disabled = true
	invincible = true
	$MovementManager.can_bonk = false
	$MovementManager.change_state($MovementManager.states["disabled"])

func enable():
	disabled = false
	invincible = false
	$MovementManager.can_bonk = true
	$MovementManager.change_state($MovementManager.states["normal"])

func move_to(pos):
	$MovementManager.move_target = pos
	$MovementManager.change_state($MovementManager.states["moveto"])

func _on_SSPDetector_body_entered(_body):
	is_on_ssp = true
func _on_SSPDetector_body_exited(_body):
	is_on_ssp = false




func _on_ItemDetector_area_entered(area):
	if not disabled:
		
		if area.get_collision_layer_bit(10): #health
			hp += area.get_parent().value
			hp = min(hp, max_hp)
			
			am.play("get_hp")
			emit_signal("hp_updated", hp, max_hp)
			area.get_parent().queue_free()
		
		
		if area.get_collision_layer_bit(11): #xp
			var active_gun = $GunManager/Guns.get_child(0)
			
			total_xp += area.get_parent().value
			active_gun.xp += area.get_parent().value

			if active_gun.xp >= active_gun.max_xp:
				if active_gun.level == active_gun.max_level:
					active_gun.xp = active_gun.max_xp
					#TODO: Flash MAX on HUD
				else:
					$GunManager.level_up(false)

			am.play("get_xp")
			emit_signal("total_xp_updated", total_xp)
			emit_signal("guns_updated", $GunManager/Guns.get_children())
			area.get_parent().queue_free()

		
		if area.get_collision_layer_bit(12): #ammo
			for w in $GunManager/Guns.get_children():
				if w.max_ammo != 0:
					w.ammo += w.max_ammo * area.value #percent of max ammo
					w.ammo = max(w.ammo, w.max_ammo)

			am.play("get_ammo")
			emit_signal("guns_updated", $WeaponManager/Guns.get_children())
			area.queue_free()


### DAMAGE, IFRAMES, AND DYING

func _on_HurtDetector_body_entered(body):
	if not disabled and body.get_collision_layer_bit(1): #enemy
		enemies_touching.append(body)
		
		var damage = body.damage_on_contact
		var knockback_direction = Vector2(sign(global_position.x - body.global_position.x), 0)
		hit(damage, knockback_direction)

func _on_HurtDetector_body_exited(body):
	enemies_touching.erase(body)

func _on_HurtDetector_area_entered(area): #KILLBOX
	if area.get_collision_layer_bit(13): #kill
		die()

func hit(damage, knockback_direction):
	if not disabled and not invincible:
		if knockback_direction != Vector2.ZERO:
			#print("Knockback in Dir: " + str(knockback_direction))
			$MovementManager.snap_vector = Vector2.ZERO
			$MovementManager.change_state($MovementManager.states["knockback"])
		if damage > 0:
			hp -= damage
			$HurtSound.play()
			emit_signal("hp_updated", hp, max_hp)
			###DamageNumber
			var damagenum = DAMAGENUMBER.instance()
			damagenum.position = global_position
			damagenum.value = damage
			get_tree().get_root().get_node("World/Front").add_child(damagenum)
			###
			do_iframes()

			if hp <= 0:
				die()

			var active_gun = $GunManager/Guns.get_child(0)
			if active_gun != null:
				active_gun.xp = active_gun.xp - (damage * 2)
				
				if active_gun.level == 1:
					active_gun.xp = max(active_gun.xp, 0)
				if active_gun.xp < 0:
					$GunManager.level_down(false)
					
				emit_signal("guns_updated", $GunManager/Guns.get_children())

func do_iframes():
	invincible = true
	$EffectPlayer.play("FlashIframe")
	yield($EffectPlayer, "animation_finished")
	invincible = false
	if not enemies_touching.empty():
		hit_again()

func hit_again(): #TODO: prioritize this for all forms of damage, not just enemies
	var toughest_enemy
	var toughtest_damage = 0
	
	for e in enemies_touching:
		if e.damage_on_contact >= toughtest_damage:
			toughest_enemy = e
			toughtest_damage = e.damage_on_contact

	var knockback_direction = Vector2(sign(global_position.x - toughest_enemy.global_position.x), 0)
	hit(toughtest_damage, knockback_direction)


func die():
	if not dead:
		dead = true
		disabled = true
		world.add_child(DEATH_CAMERA.instance())
		visible = false
		
		var explosion = EXPLOSION.instance()
		explosion.position = global_position
		world.get_node("Front").add_child(explosion)
		
		world.get_node("UILayer").add_child(load("res://src/UI/DeathScreen.tscn").instance())
		if world.has_node("UILayer/HUD"):
			world.get_node("UILayer/HUD").free()
		queue_free()

### MISC

#TODO: clean these up and get rid of them 

func update_inventory():
	emit_signal("inventory_updated", inventory)

func setup_hud():
	emit_signal("hp_updated", hp, max_hp)
	emit_signal("total_xp_updated", total_xp)
	emit_signal("guns_updated", $GunManager/Guns.get_children())


func connect_inventory():
	#if this is always null when ready is called does it do anything? why do we have this?
	var item_menu = get_tree().get_root().get_node_or_null("World/UILayer/Inventory")
	if item_menu:
		var _err = connect("inventory_updated", item_menu, "_on_inventory_updated")
