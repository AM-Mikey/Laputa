@icon("res://assets/Icon/PlayerIcon.png")
extends CharacterBody2D
class_name Player

#const POPUP = preload("res://src/UI/PopupText.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const DEATH_CAMERA = preload("res://src/Utility/DeathCamera.tscn")
const EXPERIENCEGET = preload("res://src/Effect/ExperienceGet.tscn")
const HEARTGET = preload("res://src/Effect/HeartGet.tscn")
const AMMOGET = preload("res://src/Effect/AmmoGet.tscn")
const PLAYER_DAMAGE_NUMBER = preload("res://src/Effect/PlayerDamageNumber.tscn")
const EXPERIENCE_NUMBER = preload("res://src/Effect/ExperienceNumber.tscn")
const HEART_NUMBER = preload("res://src/Effect/HeartNumber.tscn")

signal hp_updated(hp, max_hp)
signal guns_updated(guns, cause, do_xp_flash)
signal xp_updated(xp, max_xp, level, max_level, do_xp_flash)
signal money_updated(money)
signal invincibility_end()


@export var hp: int = 16
@export var max_hp: int = 16
@export var money: int = 0
@export var iframe_time: float = 1.5

#STATES

var invincible = false
var disabled = false
var can_input = true
@export var die_from_falling = true

#var is_on_conveyor = false
var enemies_touching = []
var is_on_ssp = false
var deny_ssp = false
var is_crouching = false
var forbid_crouching = false
var is_in_water = false
var is_in_coyote = false
var dead = false
@export var controller_id: int = 0


var inventory: Array
var topic_array: Array = ["child", "sasuke", "basil", "general"]
var inspect_target: Node = null
var experience_number: Node = null
var damage_number: Node = null
var heart_number: Node = null

var move_dir := Vector2.LEFT
var look_dir := Vector2i.LEFT
var direction_lock := Vector2i.ZERO
var shoot_dir := Vector2.LEFT

enum SoundProfile {NORMAL, UNDERWATER}
var sound_profile = SoundProfile.NORMAL:
	set(val):
		sound_profile = val
		if (sound_profile == SoundProfile.UNDERWATER):
			am.underwater_attenuate(true)
		else:
			am.underwater_attenuate(false)



@onready var world = get_tree().get_root().get_node("World")
@onready var HUD
@onready var mm = get_node("MovementManager")
@onready var gm = get_node("GunManager")
@onready var guns = get_node("GunManager/Guns")
@onready var iframe_timer = %IframeTimer

func _ready():
	connect_inventory()
#	if weapon_array.front() != null: TODO:fix
#		$WeaponSprite.texture = weapon_array.front().texture
	await get_tree().process_frame
	#$SSPDetector.monitoring = true #patch, some weird bug detects ssp on startup


func disable():
	disabled = true
	can_input = false
	invincible = true
	mm.change_state("disabled")
	return

func enable():
	disabled = false
	can_input = true
	invincible = false
	if mm.cached_state:
		#print("change state via player enable to cached state")
		mm.change_state(mm.cached_state.name.to_lower())
		return
	else:
		mm.change_state("run")
		return


### ACTIONS

func move_to(pos):
	mm.move_target = pos
	mm.change_state("moveto")
	return

func do_step(): #TODO: this is a failsafe, only works with run animations. for some reason it was playing twice on animation blend time
	if $Sprite2D.frame_coords.x == 1 or $Sprite2D.frame_coords.x == 7:
		am.play("pc_step")

func enemy_entered(enemy):
	enemies_touching.append(enemy)
	var damage = enemy.damage_on_contact
	var touching_distance = abs((global_position.x /16.0) - (enemy.global_position.x /16.0)) #this calculation returns a number between -1 and 1 based on how many tiles they are away
	var touching_dir = sign(global_position.x - enemy.global_position.x)
	var knockback_direction = Vector2((min(touching_distance, 1) * touching_dir), 0) #note this will always return the max direction for enemies of size greater than one tile.
	#print("kb: ", knockback_direction)
	hit(damage, knockback_direction)

func enemy_exited(enemy):
	enemies_touching.erase(enemy)

func hit(damage, knockback_direction):
	if not disabled and not invincible:
		if damage > 0:
			hp -= damage
			am.play("pc_hurt")
			emit_signal("hp_updated", hp, max_hp)
			if experience_number != null: experience_number.queue_free()
			if heart_number != null: heart_number.queue_free()
			if damage_number == null: #no damage_number
				damage_number = PLAYER_DAMAGE_NUMBER.instantiate()
				damage_number.value = damage
				if hp <= 0:
					damage_number.position = global_position
					damage_number.position.y -= 18
					get_tree().get_root().get_node("World/Front").add_child(damage_number)
					die()
				else:
					damage_number.position.y -= 18
					add_child(damage_number)
					do_iframes()
			else: #already have a damage_number
				damage_number.value += damage
				damage_number.reset()
				do_iframes()
				if hp <= 0:
					damage_number.position = global_position
					damage_number.position.y -= 18
					damage_number.reparent(get_tree().get_root().get_node("World/Front"))
					die()


			var active_gun = guns.get_child(0)
			if active_gun != null:
				active_gun.xp = active_gun.xp - (damage * 2)
				if active_gun.level == 1:
					active_gun.xp = max(active_gun.xp, 0)
				if active_gun.xp < 0:
					$GunManager.level_down(false)
				emit_signal("guns_updated", guns.get_children())

		if knockback_direction != Vector2.ZERO:
			#print("Knockback in Dir: " + str(knockback_direction))
			mm.knockback_direction = knockback_direction
			mm.snap_vector = Vector2.ZERO
			mm.change_state("knockback")


func do_iframes():
	invincible = true
	$EffectPlayer.play("FlashIframe")
	iframe_timer.start(iframe_time)


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

		world.uig.add_child(load("res://src/UI/DeathScreen.tscn").instantiate())
		if world.has_node("UILayer/UIGroup/HUD"):
			world.get_node("UILayer/UIGroup/HUD").free()
		queue_free()



### SIGNALS ###
func _on_IframeTimer_timeout() -> void:
	invincible = false
	emit_signal("invincibility_end")
	$EffectPlayer.stop()
	if not enemies_touching.is_empty():
		hit_again()


func _on_SSPDetector_body_entered(_body):
	if not deny_ssp:
		is_on_ssp = true

func _on_SSPDetector_body_exited(_body):
	is_on_ssp = false

func _on_SSPWorldDetector_body_entered(_body):
	deny_ssp = true

func _on_SSPWorldDetector_body_exited(_body):
	deny_ssp = false
	if $SSPDetector.has_overlapping_bodies():
		is_on_ssp = true


func _on_ItemDetector_area_entered(area):
	if disabled: return

	if area.get_collision_layer_value(11): #health
		var heart_pickup = area.get_parent()
		var hp_before = hp
		hp += heart_pickup.value
		hp = min(hp, max_hp)
		am.play("get_hp")
		var heart_get = HEARTGET.instantiate()
		heart_get.position = heart_pickup.global_position

		if hp - hp_before > 0: #health gained
			if damage_number != null: damage_number.queue_free()
			if experience_number != null: experience_number.queue_free()
			if heart_number == null:
				heart_number = HEART_NUMBER.instantiate()
				heart_number.value = hp - hp_before
				heart_number.position.y -= 18
				add_child(heart_number)
			else:
				heart_number.value += hp - hp_before
				heart_number.reset()

		world.get_node("Front").add_child(heart_get)
		emit_signal("hp_updated", hp, max_hp)
		heart_pickup.queue_free()


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

		if damage_number != null: damage_number.queue_free()
		if heart_number != null: heart_number.queue_free()
		if experience_number == null:
			experience_number = EXPERIENCE_NUMBER.instantiate()
			experience_number.value = experience_pickup.value
			experience_number.position.y -= 18
			add_child(experience_number)
		else:
			experience_number.value += experience_pickup.value
			experience_number.reset()

		emit_signal("money_updated", money)
		emit_signal("guns_updated", guns.get_children(), "xp", true)
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
		emit_signal("guns_updated", guns.get_children(), "getammo")
		ammo_pickup.queue_free()


func _on_Ear_area_entered(_area):
	sound_profile = SoundProfile.UNDERWATER

func _on_Ear_area_exited(_area):
	sound_profile = SoundProfile.NORMAL


#func _on_HurtDetector_area_entered(area): #KILLBOX #TODO: reverse this!
	#if area.get_collision_layer_value(14): #kill
		#die()

### MISC


#TODO: clean these up and get rid of them
func update_inventory():
	emit_signal("inventory_updated", inventory)

func setup_hud():
	var active_gun = guns.get_child(0)
	emit_signal("hp_updated", hp, max_hp)
	emit_signal("guns_updated", guns.get_children(), "setup")
	emit_signal("xp_updated", active_gun.xp, active_gun.max_xp, active_gun.level, active_gun.max_level)
	emit_signal("money_updated", money)


func connect_inventory():
	#if this is always null when ready is called does it do anything? why do we have this?
	var item_menu = get_tree().get_root().get_node_or_null("World/UILayer/UIGroup/Inventory")
	if item_menu:
		var _err = connect("inventory_updated", Callable(item_menu, "_on_inventory_updated"))
