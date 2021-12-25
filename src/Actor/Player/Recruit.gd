#TODO re-extend to actor once we remove movement from actor.gd
extends KinematicBody2D
class_name Recruit, "res://assets/Icon/PlayerIcon.png"

#const POPUP = preload("res://src/UI/PopupText.tscn")
const LEVELUP = preload("res://src/Effect/LevelUp.tscn")
const LEVELDOWN = preload("res://src/Effect/LevelDown.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const DEATH_CAMERA = preload("res://src/Utility/DeathCamera.tscn")
const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")


var sfx_get_heart = load("res://assets/SFX/Placeholder/snd_health_refill.ogg")
var sfx_get_xp = load("res://assets/SFX/Placeholder/snd_get_xp.ogg")
var sfx_get_ammo = load("res://assets/SFX/Placeholder/snd_get_missile.ogg")


signal hp_updated(hp, max_hp)
signal total_xp_updated(total_xp)
signal weapons_updated(weapon_array)





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
var weapon_array: Array = [load("res://src/Weapon/Revolver1.tres"), load("res://src/Weapon/GrenadeLauncher1.tres"), load("res://src/Weapon/MachinePistol1.tres"), load("res://src/Weapon/Shotgun1.tres")]


var move_dir = Vector2.LEFT
var face_dir = Vector2.LEFT
var shoot_dir = Vector2.LEFT






onready var world = get_tree().get_root().get_node("World")
onready var HUD


func _ready():
	connect_inventory()

	
	
	
	if weapon_array.front() != null:
		$WeaponSprite.texture = weapon_array.front().texture
	

func _input(event):
	if not disabled:
		if event.is_action_pressed("debug_level_up"):
			if weapon_array.front().level < weapon_array.front().max_level:
				level_up(true)

		if event.is_action_pressed("debug_level_down"):
			if weapon_array.front().level != 1:
				level_down(true)
		
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
			
			$PickupSound.stream = sfx_get_heart
			$PickupSound.play()
			emit_signal("hp_updated", hp, max_hp)
			area.get_parent().queue_free()
		
		if area.get_collision_layer_bit(11): #xp
			var wp = weapon_array.front()
			
			total_xp += area.get_parent().value
			wp.xp += area.get_parent().value

			if wp.xp >= wp.max_xp: #level up
				if wp.level == wp.max_level: #already max level
					wp.xp = wp.max_xp
					#TODO: Flash MAX on HUD
				else:
					level_up(false)

			$PickupSound.stream = sfx_get_xp
			$PickupSound.play()
			emit_signal("total_xp_updated", total_xp)
			emit_signal("weapons_updated", weapon_array)
			area.get_parent().queue_free()

		
		if area.get_collision_layer_bit(12): #ammo
			for w in weapon_array:
				if w.needs_ammo:
					w.ammo += w.max_ammo * area.value #percent of max ammo
					w.ammo = max(w.ammo, w.max_ammo)

			$PickupSound.stream = sfx_get_ammo
			$PickupSound.play()
			emit_signal("weapons_updated", weapon_array)
			area.queue_free()


func level_up(debug):
	var last_weapon = weapon_array.front()
	var next_weapon = load(last_weapon.resource_path.replace(last_weapon.level, last_weapon.level + 1))
	var saved_xp = 0 if debug else last_weapon.xp - last_weapon.max_xp
	var saved_ammo = last_weapon.ammo
	
	weapon_array.pop_front()
	weapon_array.push_front(next_weapon)
	weapon_array.front().ammo = saved_ammo
	weapon_array.front().xp = saved_xp
	emit_signal("weapons_updated", weapon_array)

	var level_up = LEVELUP.instance()
	get_tree().get_root().get_node("World/Front").add_child(level_up)
	level_up.position = global_position

func level_down(debug):
		var last_weapon = weapon_array.front()
		var next_weapon = load(last_weapon.resource_path.replace(last_weapon.level, last_weapon.level - 1))
		var saved_xp = last_weapon.xp #negative number
		var saved_ammo = last_weapon.ammo
		
		weapon_array.pop_front()
		weapon_array.push_front(next_weapon)
		weapon_array.front().ammo = saved_ammo
		weapon_array.front().xp = 0 if debug else weapon_array.front().max_xp + saved_xp
		emit_signal("weapons_updated", weapon_array)

		var level_down = LEVELDOWN.instance()
		get_tree().get_root().get_node("World/Front").add_child(level_down)
		level_down.position = global_position

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

			var current_weapon = weapon_array.front()
			if current_weapon != null:
				current_weapon.xp = current_weapon.xp - (damage * 2)
				
				if current_weapon.level == 1:
					current_weapon.xp = max(current_weapon.xp, 0)
				if weapon_array.front().xp < 0:
					level_down(false)
					
				emit_signal("weapons_updated", weapon_array)

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

func restore_hp(): #TODO: remove this and merge with health canister
	$PickupSound.stream = sfx_get_heart
	$PickupSound.play()
	hp = max_hp
	emit_signal("hp_updated", hp, max_hp)
	
func update_inventory():
	emit_signal("inventory_updated", inventory)

func setup_hud():
	emit_signal("hp_updated", hp, max_hp)
	emit_signal("total_xp_updated", total_xp)
	emit_signal("weapons_updated", weapon_array)


func connect_inventory():
	#if this is always null when ready is called does it do anything? why do we have this?
	var item_menu = get_tree().get_root().get_node_or_null("World/UILayer/Inventory")
	if item_menu:
		var _err = connect("inventory_updated", item_menu, "_on_inventory_updated")
