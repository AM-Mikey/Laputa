extends Player

#const POPUP = preload("res://src/UI/PopupText.tscn")
const LEVELUP = preload("res://src/Effect/LevelUp.tscn")
const LEVELDOWN = preload("res://src/Effect/LevelDown.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const DEATHCAM = preload("res://src/Utility/DeathCam.tscn")



var sfx_get_heart = load("res://assets/SFX/Placeholder/snd_health_refill.ogg")
var sfx_get_xp = load("res://assets/SFX/Placeholder/snd_get_xp.ogg")
var sfx_get_ammo = load("res://assets/SFX/Placeholder/snd_get_missile.ogg")


signal hp_updated(hp, max_hp)
signal total_xp_updated(total_xp)
signal weapons_updated(weapon_array)





export var hp: int = 100
export var max_hp: int = 100
var total_xp: int = 0


#STATES
var direction_lock = Vector2.ZERO
var debug_flying = false

var invincible = false
var disabled = true
var knockback = false

var is_in_enemy = false
var is_on_ladder = false
var is_on_ssp = false
var is_inspecting = false
#var is_in_spikes = false

var displaying_debug_info = false


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
		if Input.is_action_just_pressed("debug_print"):
			debug_print()
		if event.is_action_pressed("level_up"):
			if weapon_array.front().level < weapon_array.front().max_level:
				print("level up via debug")

				if weapon_array.front().level == weapon_array.front().max_level and weapon_array.front().xp == weapon_array.front().max_xp: pass
				else: weapon_array.front().xp = weapon_array.front().max_xp

				var next_level = load(weapon_array.front().resource_path.replace(weapon_array.front().level,weapon_array.front().level + 1))
				var saved_xp = weapon_array.front().xp - weapon_array.front().max_xp
				var saved_ammo = weapon_array.front().ammo
				weapon_array.pop_front()
				weapon_array.push_front(next_level)
				weapon_array.front().ammo = saved_ammo
				weapon_array.front().xp = saved_xp
				emit_signal("weapons_updated", weapon_array)

				var level_up = LEVELUP.instance()
				get_tree().get_root().get_node("World/Front").add_child(level_up)
				level_up.position = global_position

				emit_signal("weapons_updated", weapon_array)

		if event.is_action_pressed("level_down"):
			if weapon_array.front().level != 1:
				print("level down via debug")
				var next_level = load(weapon_array.front().resource_path.replace(weapon_array.front().level, weapon_array.front().level - 1))
				var saved_xp = weapon_array.front().xp #negative number
				var saved_ammo = weapon_array.front().ammo
				weapon_array.pop_front()
				weapon_array.push_front(next_level)
				weapon_array.front().ammo = saved_ammo
				weapon_array.front().xp = weapon_array.front().max_xp + saved_xp
				emit_signal("weapons_updated", weapon_array)

				var level_down = LEVELDOWN.instance()
				get_tree().get_root().get_node("World/Front").add_child(level_down)




func _on_SSPDetector_body_entered(_body):
	is_on_ssp = true


func _on_SSPDetector_body_exited(_body):
	is_on_ssp = false
	
	
	
func debug_print():
	if not displaying_debug_info:
		displaying_debug_info = true
		var debug_info = load("res://src/UI//Debug/DebugInfo.tscn").instance()
		world.get_node("UILayer").add_child(debug_info)
	else:
		displaying_debug_info = false
		world.get_node("UILayer/DebugInfo").queue_free()


func _on_ItemDetector_area_entered(area):
	if disabled != true:
		
		if area.get_collision_layer_bit(10): #health
			hp += area.get_parent().value
			$PickupSound.stream = sfx_get_heart
			$PickupSound.play()
			if hp > max_hp:
				hp = max_hp
			emit_signal("hp_updated", hp, max_hp)
			area.get_parent().queue_free()
		
		if area.get_collision_layer_bit(11): #xp
			total_xp += area.get_parent().value
			emit_signal("total_xp_updated", total_xp)
			if weapon_array.front().level == weapon_array.front().max_level and weapon_array.front().xp == weapon_array.front().max_xp:
				pass
			else:
				weapon_array.front().xp += area.get_parent().value

			if weapon_array.front().xp >= weapon_array.front().max_xp: #level up
				if weapon_array.front().level == weapon_array.front().max_level: #already max level
					print("already max level")
					$PickupSound.stream = sfx_get_xp
					$PickupSound.play()
				
					emit_signal("weapons_updated", weapon_array)
					area.get_parent().queue_free()
					
				else: #leveling up normally
					print("level up normally")
					var next_level = load(weapon_array.front().resource_path.replace(weapon_array.front().level,weapon_array.front().level + 1))
					var saved_xp = weapon_array.front().xp - weapon_array.front().max_xp
					var saved_ammo = weapon_array.front().ammo
					weapon_array.pop_front()
					weapon_array.push_front(next_level)
					weapon_array.front().ammo = saved_ammo
					weapon_array.front().xp = saved_xp
					emit_signal("weapons_updated", weapon_array)
					area.get_parent().queue_free()
					
					var level_up = LEVELUP.instance()
					get_tree().get_root().get_node("World/Front").add_child(level_up)
					level_up.position = global_position
					
					
					emit_signal("weapons_updated", weapon_array)

					
			else: #not leveling just collecting xp
				print("no level just collect xp")
				$PickupSound.stream = sfx_get_xp
				$PickupSound.play()
				emit_signal("weapons_updated", weapon_array)
				area.get_parent().queue_free()
		
		
		if area.get_collision_layer_bit(12): #ammo
			for w in weapon_array:
				if w.needs_ammo:
					w.ammo += w.max_ammo * area.value #percent of max ammo
					if w.ammo > w.max_ammo:
						w.ammo = w.max_ammo

			$PickupSound.stream = sfx_get_ammo
			$PickupSound.play()
			
			var needs_ammo = weapon_array.front().needs_ammo
			var ammo = weapon_array.front().ammo
			var max_ammo = weapon_array.front().max_ammo
			emit_signal("weapons_updated", weapon_array)
			area.queue_free()

func do_iframes(damage, knockback_direction):
	print("do_iframes_started")
	invincible = true
	$EffectPlayer.play("FlashIframe")
	yield($EffectPlayer, "animation_finished")
	invincible = false
	print("do_iframes_finished")
#	if is_in_enemy == true: #check if they are REALLY still in an enemy
#		#there was an issue with this failsafe, can't remember what it was
#		hit(damage, knockback_direction)
#	if is_in_spikes == true:
#		hit(damage, knockback_direction)
		

func hit(damage, knockback_direction):
	if not disabled and not invincible:
		if knockback_direction != Vector2.ZERO:
			$MovementManager.snap_vector = Vector2.ZERO
			knockback = true
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
			do_iframes(damage, knockback_direction)

			if hp <= 0:
				die()

			if weapon_array.front() == null:
				return
			elif weapon_array.front().level == 1 and weapon_array.front().xp == 0: #if not level 1 and 0 xp, take away xp
				return
			else:
				weapon_array.front().xp = max(weapon_array.front().xp - (damage * 2), 0)
				emit_signal("weapons_updated", weapon_array)
			
			if weapon_array.front().xp < 0 and weapon_array.front().level != 1: #level down
				var next_level = load(weapon_array.front().resource_path.replace(weapon_array.front().level, weapon_array.front().level - 1))
				var saved_xp = weapon_array.front().xp #negative number
				var saved_ammo = weapon_array.front().ammo
				weapon_array.pop_front()
				weapon_array.push_front(next_level)
				weapon_array.front().ammo = saved_ammo
				weapon_array.front().xp = weapon_array.front().max_xp + saved_xp
				emit_signal("weapons_updated", weapon_array)
				
				var level_down = LEVELDOWN.instance()
				get_tree().get_root().get_node("World/Front").add_child(level_down)
				level_down.position = global_position


func die():
	if not dead:
		dead = true
		disabled = true
		world.add_child(DEATHCAM.instance())
		visible = false
		
		var explosion = EXPLOSION.instance()
		explosion.position = global_position
		world.get_node("Front").add_child(explosion)
		
		world.get_node("UILayer").add_child(load("res://src/UI/DeathScreen.tscn").instance())
		if world.has_node("UILayer/HUD"):
			world.get_node("UILayer/HUD").free()
		queue_free()

func _on_HurtDetector_body_entered(body):
	if not disabled:
		if body.get_collision_layer_bit(1): #enemy
			var damage = body.damage_on_contact
			is_in_enemy = true
			var knockback_direction = Vector2(sign(global_position.x - body.global_position.x), 0)
			hit(damage, knockback_direction)


func _on_HurtDetector_body_exited(_body):
	is_in_enemy = false

func _on_HurtDetector_area_entered(area):
	if not disabled:
		if area.get_collision_layer_bit(13): #kill
			die()
			


#TODO clean these up and get rid of them 

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
		connect("inventory_updated", item_menu, "_on_inventory_updated")
