extends Actor
class_name Player, "res://assets/Icon/PlayerIcon.png"

const EFFECT = preload("res://src/Effect/Effect.tscn")
const TEXTEFFECT = preload("res://src/Effect/TextEffect.tscn")

const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0

signal setup_ui(hp, max_hp, total_xp, weapon_level, weapon_xp, weapon_xp_min, weapon_xp_max, weapon_needs_ammo, weapon_ammo, weapon_max_ammo)
signal player_health_updated(hp, max_hp)
signal player_max_health_updated(max_hp)
signal player_experience_updated(total_xp, level, weapon_xp, weapon_xp_min, weapon_xp_max)
signal ammo_updated(needs_ammo, ammo, max_ammo)
signal inventory_updated(inventory)


var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

export var dodge_speed = Vector2(700, 100)
export var dodge_time: float = (0.3)

export var forgiveness_time = 0.05
var knockback = false
var knockback_direction: Vector2

export var hp: int = 100
export var max_hp: int = 100
var invincible = false
var colliding = true
var disabled = false
var is_in_enemy = false
var is_in_hazard = false
var is_on_ladder = false
var is_in_water = false
var is_in_spikes = false
var can_fall_through = false
var enemy_on_head = false
var debug_active = false
export var debug_speed = 500

var total_xp: int = 0

var inventory: Array
var topic_array: Array = ["ham", "cheese", "marbles", "balogna"]
var weapon_array: Array = [load("res://src/Weapon/%s" % "Revolver1" + ".tres"), load("res://src/Weapon/%s" % "GrenadeLauncher" + ".tres"), load("res://src/Weapon/MachinePistol1.tres"), load("res://src/Weapon/Shotgun.tres")]


func _ready():
#	for w in weapon_array:
#		print("ssd")
#		var weapon = load("res://src/Weapon/%s" % w + ".tres")
#		weapon.xp = 0
#		if weapon.needs_ammo:
#			weapon.ammo = weapon.max_ammo
#			ResourceSaver.save("res://src/Weapon/%s" % w + ".tres", weapon)
#	$WeaponManager.update_weapon()
	
	var item_menu = get_tree().get_root().get_node("World/UILayer/ItemMenu")
	connect("inventory_updated", item_menu, "_on_inventory_updated")
	
	if weapon_array.front() != null:
		emit_signal("setup_ui", hp, max_hp, total_xp, weapon_array.front().level, weapon_array.front().xp, weapon_array.front().max_xp, weapon_array.front().needs_ammo, weapon_array.front().ammo, weapon_array.front().max_ammo, weapon_array.front().icon_texture)
		$WeaponSprite.texture = weapon_array.front().texture
	else:
		emit_signal("setup_ui", hp, max_hp, total_xp, 0, 0, 1, false, 0, 0, null)

func _input(event):
	if disabled != true:
		if weapon_array.size() > 1: #only swap if more than one weapon
			if event.is_action_pressed("weapon_left"):
				#ResourceSaver.save("res://src/Weapon/%s" % weapon_array.front() + ".tres", weapon_array.front())
				shift_weapon_left()
				$WeaponManager.update_weapon()
				play_weapon_change_sound()

			if event.is_action_pressed("weapon_right"):
				#ResourceSaver.save("res://src/Weapon/%s" % weapon_array.front() + ".tres", weapon_array.front())
				shift_weapon_right()
				$WeaponManager.update_weapon()
				play_weapon_change_sound()
		
		if event.is_action_pressed("toggle_debug"):
			debug_mode()
		
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
				$WeaponManager.update_weapon()
				
				var text = TEXTEFFECT.instance()
				get_parent().add_child(text)
				text.position = global_position
				var player = text.get_node("AnimationPlayer")
				player.play("LevelUp")
				var audio = text.get_node("AudioStreamPlayer2D")
				audio.stream = load("res://assets/SFX/snd_level_up.ogg")
				audio.play()
				update_xp()
				yield(player, "animation_finished")
				text.queue_free()
			
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
				$WeaponManager.update_weapon()
				
				var text = TEXTEFFECT.instance()
				get_parent().add_child(text)
				text.position = global_position
				var player = text.get_node("AnimationPlayer")
				player.play("LevelDown")
				yield(player, "animation_finished")
				text.queue_free()

func shift_weapon_left():
		var weapon_to_move = weapon_array.pop_back()
		weapon_array.push_front(weapon_to_move)
		#weapon_array.front() = load("res://src/Weapon/%s" % weapon_array.front() + ".tres")
		
func shift_weapon_right():
		var weapon_to_move = weapon_array.pop_front()
		weapon_array.push_back(weapon_to_move)
		#weapon_array.front() = load("res://src/Weapon/%s" % weapon_array.front() + ".tres")

func play_weapon_change_sound():
	var audio = get_node("WeaponManager/WeaponAudio")
	audio.stream = load("res://assets/SFX/snd_switchweapon.ogg")
	audio.play()

func hit(damage, knockback_direction):
	if disabled != true:
		if invincible == false:
			hp -= damage
			if damage > 0:
				emit_signal("player_health_updated", hp, max_hp)
				###DamageNumber
				var damagenum = DAMAGENUMBER.instance()
				damagenum.position = global_position
				damagenum.value = damage
				get_parent().add_child(damagenum)
				###
				do_iframes(damage, knockback_direction)
			if knockback_direction != Vector2.ZERO:
				snap_vector = Vector2.ZERO
				knockback = true
			
			if hp <= 0:
				die()
			
			if weapon_array.front() == null:
				return
			elif weapon_array.front().level == 1 and weapon_array.front().xp == 0: #if not level 1 and 0 xp, take away xp
				return
			else:
				weapon_array.front().xp = max(weapon_array.front().xp - (damage * 2), 0)
				emit_signal("player_experience_updated", total_xp, weapon_array.front().level, weapon_array.front().max_level, weapon_array.front().xp, weapon_array.front().max_xp)
			
			if weapon_array.front().xp < 0 and weapon_array.front().level != 1: #level down
				var next_level = load(weapon_array.front().resource_path.replace(weapon_array.front().level, weapon_array.front().level - 1))
				var saved_xp = weapon_array.front().xp #negative number
				var saved_ammo = weapon_array.front().ammo
				weapon_array.pop_front()
				weapon_array.push_front(next_level)
				weapon_array.front().ammo = saved_ammo
				weapon_array.front().xp = weapon_array.front().max_xp + saved_xp
				$WeaponManager.update_weapon()
				
				var text = TEXTEFFECT.instance()
				get_parent().add_child(text)
				text.position = global_position
				var player = text.get_node("AnimationPlayer")
				player.play("LevelDown")
				yield(player, "animation_finished")
				text.queue_free()
#				var audio = text.get_node("AudioStreamPlayer2D") 				#need a SFX for this
#				audio.stream = load("res://assets/SFX/snd_level_down.ogg")
#				audio.play()
			


func do_iframes(damage, knockback_direction):
	print("do_iframes_started")
	invincible = true
	$EffectPlayer.play("FlashIframe")
	yield($EffectPlayer, "animation_finished")
	invincible = false
	print("do_iframes_finished")
	if is_in_enemy == true: #check if they are REALLY still in an enemy
		#there was an issue with this failsafe, can't remember what it was
		hit(damage, knockback_direction)
	if is_in_hazard == true:
		hit(damage, knockback_direction)
	if is_in_spikes == true:
		hit(damage, knockback_direction)
		
func die():
	if dead == false:
		dead = true
		var effect = EFFECT.instance()
		get_parent().add_child(effect)
		effect.position = global_position
		
		var player = effect.get_node("AnimationPlayer")
		player.play("Explode")
		visible = false
		$CollisionShape2D.disabled = true
		yield(player, "animation_finished")
		print("removed enemy and effect")
		effect.queue_free()
	#	yield(self, "do_damage_num_finsihed")
		queue_free()
		get_tree().reload_current_scene()




func _on_HurtDetector_body_entered(body):
	if not disabled:
		if body.get_collision_layer_bit(1): #enemy
			var damage = body.damage_on_contact
			is_in_enemy = true
			knockback_direction = Vector2(sign(global_position.x - body.global_position.x), 0)
			hit(damage, knockback_direction)


func _on_HurtDetector_body_exited(body):
	is_in_enemy = false

func _on_HurtDetector_area_entered(area):
	if not disabled:
		if area.get_collision_layer_bit(13): #kill
			die()
	
		if area.get_collision_layer_bit(14): #hazard
			var damage = area.damage_on_contact
			is_in_hazard = true
			#knockback_direction = Vector2(sign(global_position.x - area.global_position.x), 0)
			hit(damage, knockback_direction)


func _on_HurtDetector_area_exited(area):
	if area.get_collision_layer_bit(14):
		is_in_hazard = false






func _on_EntityDetector_body_entered(body):
	pass




func _on_EntityDetector_area_entered(area):
	if disabled != true:
		
		if area.get_collision_layer_bit(10): #health
			hp += area.get_parent().value
			$PickupSound.stream = load("res://assets/SFX/snd_health_refill.ogg")
			$PickupSound.play()
			if hp > max_hp:
				hp = max_hp
			emit_signal("player_health_updated", hp, max_hp)
			area.get_parent().queue_free()
		
		if area.get_collision_layer_bit(11): #xp
			total_xp += area.get_parent().value
			if weapon_array.front().level == weapon_array.front().max_level and weapon_array.front().xp == weapon_array.front().max_xp:
				pass
			else:
				weapon_array.front().xp += area.get_parent().value

			if weapon_array.front().xp >= weapon_array.front().max_xp: #level up
				if weapon_array.front().level == weapon_array.front().max_level: #already max level
					print("already max level")
					$PickupSound.stream = load("res://assets/SFX/snd_get_xp.ogg")
					$PickupSound.play()
					emit_signal("player_experience_updated", total_xp, weapon_array.front().level, weapon_array.front().max_level, weapon_array.front().xp, weapon_array.front().max_xp)
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
					$WeaponManager.update_weapon()
					area.get_parent().queue_free()
					
					var text = TEXTEFFECT.instance()
					get_parent().add_child(text)
					text.position = global_position
					var player = text.get_node("AnimationPlayer")
					player.play("LevelUp")
					var audio = text.get_node("AudioStreamPlayer2D")
					audio.stream = load("res://assets/SFX/snd_level_up.ogg")
					audio.play()
					update_xp()
					yield(player, "animation_finished")
					text.queue_free()
					
			else: #not leveling just collecting xp
				print("no level just collect xp")
				$PickupSound.stream = load("res://assets/SFX/snd_get_xp.ogg")
				$PickupSound.play()
				update_xp()
				area.get_parent().queue_free()
		
		
		if area.get_collision_layer_bit(12): #ammo
			for w in weapon_array:
				if w.needs_ammo:
					w.ammo += w.max_ammo * area.value #percent of max ammo
					if w.ammo > w.max_ammo:
						w.ammo = w.max_ammo

			$PickupSound.stream = load("res://assets/SFX/snd_get_missile.ogg")
			$PickupSound.play()
			
			var needs_ammo = weapon_array.front().needs_ammo
			var ammo = weapon_array.front().ammo
			var max_ammo = weapon_array.front().max_ammo
			emit_signal("ammo_updated", needs_ammo, ammo, max_ammo)
			area.queue_free()
			




func _on_HeadDetector_body_entered(body): #DEPRECIATED CODE, SINCE ENEMIES CANNOT COLLIDE WITH PLAYER ANYMORE
	if body.get_collision_layer_bit(1): #enemy
		print("enemy on player head")
		
		if not body.get_collision_mask_bit(1): #if body does not collide with player, ignore
			return
		
		enemy_on_head = true
		yield(get_tree().create_timer(.1), "timeout")
		while enemy_on_head == true and not dead: #checks if it's still the case
			var enemy_push_dir = Vector2(sign(body.global_position.x - global_position.x), -1)
			print("pushing enemy in direction:", enemy_push_dir)
			body.move_and_slide(Vector2(enemy_push_dir.x * 1000 * get_process_delta_time(), enemy_push_dir.y * 10), FLOOR_NORMAL)
			yield(get_tree(),"idle_frame")

func _on_HeadDetector_body_exited(body): #not the best way, cant tell if multiple enemies are on head
	enemy_on_head = false



func restore_hp():
	$PickupSound.stream = load("res://assets/SFX/snd_health_refill.ogg")
	$PickupSound.play()
	hp = max_hp
	emit_signal("player_health_updated", hp, max_hp)
	
func update_hp():
	emit_signal("player_health_updated", hp, max_hp)

func update_max_hp():
	emit_signal("player_max_health_updated", max_hp)

func update_xp():
	emit_signal("player_experience_updated", total_xp, weapon_array.front().level, weapon_array.front().max_level, weapon_array.front().xp, weapon_array.front().max_xp)

func update_inventory():
	emit_signal("inventory_updated", inventory)

func debug(move_direction, look_direction):
	if Input.is_action_just_pressed("debug"):
		print("DEBUG STATS")
		print("player hp: ", hp)
		print("player max_hp: ", max_hp)
		print("player position: ", global_position)
		print("move_direction: ", move_direction)
		print("look_direction: ", look_direction)
		print("total xp: ", total_xp)
		print("weapon xp: ", weapon_array.front().xp)
		print("weapon level: ", weapon_array.front().level)
		print("weapon max_xp ", weapon_array.front().max_xp)
		print("forgiveness timer time left: ", $ForgivenessTimer.time_left)
		print("is on floor: ", is_on_floor())
		print("camera offset: ", $Camera2D.offset)
		print("camera position: ", $Camera2D.global_position)
		
		print("screen size: ", OS.get_screen_size())
		print("window size: ", OS.get_window_size())
		print("viewport size: ", get_tree().get_root().size)

func debug_mode():
	if debug_active == false:
		print("debug mode: ON")
		debug_active = true
		invincible = true
		colliding = false
		$CollisionShape2D.disabled = true
		$HurtDetector.monitoring = false
		$ItemDetector.monitoring = false
	
	elif debug_active == true:
		print("debug mode: OFF")
		is_in_water = false
		is_on_ladder = false
		debug_active = false
		invincible = false
		colliding = true
		$CollisionShape2D.disabled = false
		$HurtDetector.monitoring = true
		$ItemDetector.monitoring = true
		
func enable():
	pass
