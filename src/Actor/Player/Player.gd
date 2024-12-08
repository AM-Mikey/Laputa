@icon("res://assets/Icon/PlayerIcon.png")
#TODO re-extend to actor once we remove movement from actor.gd
extends CharacterBody2D
class_name Player

#const POPUP = preload("res://src/UI/PopupText.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const DEATH_CAMERA = preload("res://src/Utility/DeathCamera.tscn")
const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const EXPERIENCEGET = preload("res://src/Effect/ExperienceGet.tscn")
const HEARTGET = preload("res://src/Effect/HeartGet.tscn")
const AMMOGET = preload("res://src/Effect/AmmoGet.tscn")


signal hp_updated(hp, max_hp)
signal guns_updated(guns)
signal xp_updated(xp, max_xp, level, max_level)
signal money_updated(money)


@export var hp: int = 16
@export var max_hp: int = 16
@export var money: int = 0


#STATES

var invincible = false
var disabled = true
var can_input = true

#var is_on_conveyor = false
var enemies_touching = []
var is_on_ssp = false
var is_crouching = false
var is_in_water = false
var is_in_coyote = false
var dead = false
@export var controller_id: int = 0


var inventory: Array
var topic_array: Array = ["child", "sasuke", "basil", "free_dialog"]
var inspect_target: Node = null

var move_dir := Vector2.LEFT
var look_dir := Vector2i.LEFT
var direction_lock := Vector2i.ZERO
var shoot_dir := Vector2.LEFT



@onready var world = get_tree().get_root().get_node("World")
@onready var HUD
@onready var mm = get_node("MovementManager")
@onready var gm = get_node("GunManager")
@onready var guns = get_node("GunManager/Guns")


func _ready():
	#add_to_group("Actors") we could declare these like all other actors... or just leave him out
	#add_to_group("Entities")
	#home = global_position
	
	connect_inventory()
#	if weapon_array.front() != null: TODO:fix
#		$WeaponSprite.texture = weapon_array.front().texture
	await get_tree().process_frame
	$SSPDetector.monitoring = true #patch, some weird bug detects ssp on startup


func disable():
	disabled = true
	can_input = false
	invincible = true
	mm.change_state("disabled")

func enable():
	disabled = false
	can_input = true
	invincible = false
	if mm.cached_state:
		mm.change_state(mm.cached_state.name.to_lower())
	else:
		mm.change_state("run")


### ACTIONS

func move_to(pos):
	mm.move_target = pos
	mm.change_state("moveto")

func do_step(): #TODO: this is a failsafe, only works with run animations. for some reason it was playing twice on animation blend time
	if $Sprite2D.frame_coords.x == 1 or $Sprite2D.frame_coords.x == 7:
		am.play("pc_step")

func hit(damage, knockback_direction):
	if not disabled and not invincible:
		if knockback_direction != Vector2.ZERO:
			#print("Knockback in Dir: " + str(knockback_direction))
			mm.snap_vector = Vector2.ZERO
			mm.change_state("knockback")
		if damage > 0:
			hp -= damage
			am.play("pc_hurt")
			emit_signal("hp_updated", hp, max_hp)
			###DamageNumber
			var damagenum = DAMAGENUMBER.instantiate()
			damagenum.position = global_position
			damagenum.value = damage
			get_tree().get_root().get_node("World/Front").add_child(damagenum)
			###
			do_iframes()

			if hp <= 0:
				die()

			var active_gun = guns.get_child(0)
			if active_gun != null:
				active_gun.xp = active_gun.xp - (damage * 2)
				
				if active_gun.level == 1:
					active_gun.xp = max(active_gun.xp, 0)
				if active_gun.xp < 0:
					$GunManager.level_down(false)
					
				emit_signal("guns_updated", guns.get_children())

func do_iframes():
	invincible = true
	$EffectPlayer.play("FlashIframe")
	await $EffectPlayer.animation_finished
	invincible = false
	if not enemies_touching.is_empty():
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
		world.add_child(DEATH_CAMERA.instantiate())
		visible = false
		
		var explosion = EXPLOSION.instantiate()
		explosion.position = global_position
		world.get_node("Front").add_child(explosion)
		
		world.get_node("UILayer").add_child(load("res://src/UI/DeathScreen.tscn").instantiate())
		if world.has_node("UILayer/HUD"):
			world.get_node("UILayer/HUD").free()
		queue_free()



### SIGNALS ###

func _on_SSPDetector_body_entered(body):
	is_on_ssp = true
func _on_SSPDetector_body_exited(_body):
	is_on_ssp = false

func _on_ItemDetector_area_entered(area):
	if disabled: return
	
	if area.get_collision_layer_value(11): #health
		hp += area.get_parent().value
		hp = min(hp, max_hp)
		am.play("get_hp")
		var heart_get = HEARTGET.instantiate()
		heart_get.position = area.get_parent().global_position
		world.get_node("Front").add_child(heart_get)
		emit_signal("hp_updated", hp, max_hp)
		area.get_parent().queue_free()
	
	
	if area.get_collision_layer_value(12): #xp
		var experience_pickup = area.get_parent()
		var active_gun = guns.get_child(0)
		money += experience_pickup.value
		active_gun.xp += experience_pickup.value
		if active_gun.xp >= active_gun.max_xp:
			if active_gun.level == active_gun.max_level:
				active_gun.xp = active_gun.max_xp
				#TODO: Flash MAX on HUD
			else:
				$GunManager.level_up(false)
		am.play("get_xp")
		var experience_get = EXPERIENCEGET.instantiate()
		experience_get.position = experience_pickup.global_position
		world.get_node("Front").add_child(experience_get)
		emit_signal("money_updated", money)
		emit_signal("guns_updated", guns.get_children())
		experience_pickup.queue_free()
	
	
	if area.get_collision_layer_value(13): #ammo
		var ammo_pickup = area.get_parent()
		for w in guns.get_children():
			if w.max_ammo != 0:
				w.ammo += int(w.max_ammo * ammo_pickup.value) #percent of max ammo
				w.ammo = min(w.ammo, w.max_ammo)
		am.play("get_ammo")
		var ammo_get = AMMOGET.instantiate()
		ammo_get.position = ammo_pickup.global_position
		world.get_node("Front").add_child(ammo_get)
		emit_signal("guns_updated", guns.get_children())
		ammo_pickup.queue_free()

func _on_HurtDetector_body_entered(body):
	if not disabled and body.get_collision_layer_value(2): #enemy
		enemies_touching.append(body)
		var damage = body.damage_on_contact
		var knockback_direction = Vector2(sign(global_position.x - body.global_position.x), 0)
		hit(damage, knockback_direction)

func _on_HurtDetector_body_exited(body):
	enemies_touching.erase(body)

func _on_HurtDetector_area_entered(area): #KILLBOX
	if area.get_collision_layer_value(14): #kill
		die()



### MISC


#TODO: clean these up and get rid of them 
func update_inventory():
	emit_signal("inventory_updated", inventory)

func setup_hud():
	var active_gun = guns.get_child(0)
	emit_signal("hp_updated", hp, max_hp)
	emit_signal("guns_updated", guns.get_children())
	emit_signal("xp_updated", active_gun.xp, active_gun.max_xp, active_gun.level, active_gun.max_level)
	emit_signal("money_updated", money)


func connect_inventory():
	#if this is always null when ready is called does it do anything? why do we have this?
	var item_menu = get_tree().get_root().get_node_or_null("World/UILayer/Inventory")
	if item_menu:
		var _err = connect("inventory_updated", Callable(item_menu, "_on_inventory_updated"))
