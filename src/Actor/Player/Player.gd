extends Actor
class_name Player, "res://assets/Icon/PlayerIcon.png"

const LEVELUP = preload("res://src/Effect/LevelUp.tscn")
const LEVELDOWN = preload("res://src/Effect/LevelDown.tscn")

const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0

var sfx_switch_weapon =  load("res://assets/SFX/Placeholder/snd_switchweapon.ogg")
var sfx_get_heart = load("res://assets/SFX/Placeholder/snd_health_refill.ogg")
var sfx_get_xp = load("res://assets/SFX/Placeholder/snd_get_xp.ogg")
var sfx_get_ammo = load("res://assets/SFX/Placeholder/snd_get_missile.ogg")

signal inventory_updated(inventory)

var face_dir = Vector2.LEFT
var shoot_dir = Vector2.LEFT

var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

export var dodge_speed = Vector2(700, 100)
export var dodge_time: float = (0.3)

export var forgiveness_time = 0.05
var knockback = false
var knockback_direction: Vector2

export var hp: int = 100
export var max_hp: int = 100
var invincible = false ##cleanup
var colliding = true
var disabled = false
var is_in_enemy = false
var is_on_ladder = false
var is_in_spikes = false ##cleanup
var can_fall_through = false
var enemy_on_head = false ##cleanup
var debug_active = false ##cleanup
export var debug_speed = 500

var total_xp: int = 0

var inventory: Array
var topic_array: Array = ["ham", "cheese", "marbles", "balogna"]
var weapon_array: Array = [load("res://src/Weapon/Revolver1.tres"), load("res://src/Weapon/GrenadeLauncher1.tres"), load("res://src/Weapon/MachinePistol1.tres"), load("res://src/Weapon/Shotgun1.tres")]

onready var HUD = get_tree().get_root().get_node("World/UILayer/HUD")

func _ready():
	var item_menu = get_tree().get_root().get_node("World/UILayer/ItemMenu")
	connect("inventory_updated", item_menu, "_on_inventory_updated")
	
	if weapon_array.front() != null:
		$WeaponSprite.texture = weapon_array.front().texture


func _input(event):
	if disabled != true:
		if weapon_array.size() > 1: #only swap if more than one weapon
			if event.is_action_pressed("weapon_left"):
				shift_weapon("left")
				update_weapon()
				play_weapon_change_sound()

			if event.is_action_pressed("weapon_right"):
				shift_weapon("right")
				update_weapon()
				play_weapon_change_sound()
		
		if event.is_action_pressed("debug_fly"):
			debug_fly()
			
		
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
				update_weapon()
				
				var level_up = LEVELUP.instance()
				get_tree().get_root().get_node("World/Front").add_child(level_up)
				level_up.position = global_position
				
				update_xp()

			
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
				update_weapon()
				
				var level_down = LEVELDOWN.instance()
				get_tree().get_root().get_node("World/Front").add_child(level_down)

func shift_weapon(direction):
	match direction:
		"left":
			var weapon_to_move = weapon_array.pop_back()
			weapon_array.push_front(weapon_to_move)
		"right":
			var weapon_to_move = weapon_array.pop_front()
			weapon_array.push_back(weapon_to_move)


func play_weapon_change_sound():
	var audio = get_node("WeaponManager/WeaponAudio")
	audio.stream = sfx_switch_weapon
	audio.play()

func hit(damage, knockback_direction):
	if disabled != true:
		if invincible == false:
			if knockback_direction != Vector2.ZERO:
				snap_vector = Vector2.ZERO
				knockback = true
			if damage > 0:
				hp -= damage
				$HurtSound.play()
				update_hp()
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
					update_xp()
				
				if weapon_array.front().xp < 0 and weapon_array.front().level != 1: #level down
					var next_level = load(weapon_array.front().resource_path.replace(weapon_array.front().level, weapon_array.front().level - 1))
					var saved_xp = weapon_array.front().xp #negative number
					var saved_ammo = weapon_array.front().ammo
					weapon_array.pop_front()
					weapon_array.push_front(next_level)
					weapon_array.front().ammo = saved_ammo
					weapon_array.front().xp = weapon_array.front().max_xp + saved_xp
					update_weapon()
					
					var level_down = LEVELDOWN.instance()
					get_tree().get_root().get_node("World/Front").add_child(level_down)
					level_down.position = global_position


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
	if is_in_spikes == true:
		hit(damage, knockback_direction)
		
func die():
	if dead == false:
		dead = true
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




func _on_ItemDetector_area_entered(area):
	if disabled != true:
		
		if area.get_collision_layer_bit(10): #health
			hp += area.get_parent().value
			$PickupSound.stream = sfx_get_heart
			$PickupSound.play()
			if hp > max_hp:
				hp = max_hp
			update_hp()
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
					$PickupSound.stream = sfx_get_xp
					$PickupSound.play()
					update_xp()
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
					update_weapon()
					area.get_parent().queue_free()
					
					var level_up = LEVELUP.instance()
					get_tree().get_root().get_node("World/Front").add_child(level_up)
					level_up.position = global_position
					
					update_xp()

					
			else: #not leveling just collecting xp
				print("no level just collect xp")
				$PickupSound.stream = sfx_get_xp
				$PickupSound.play()
				update_xp()
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
			update_ammo()
			area.queue_free()
			




func _on_HeadDetector_body_entered(body): #DEPRECIATED CODE, SINCE ENEMIES CANNOT COLLIDE WITH PLAYER ANYMORE ##is it?
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
	$PickupSound.stream = sfx_get_heart
	$PickupSound.play()
	hp = max_hp
	update_hp()
	
func update_hp():
	HUD.update_hp()

func update_xp():
	HUD.update_xp(true)

func update_ammo():
	HUD.update_ammo()

func update_weapon():
	$WeaponManager.update_weapon()

func update_inventory():
	emit_signal("inventory_updated", inventory)

func debug_print(move_direction, look_direction):
	if Input.is_action_just_pressed("debug_print"):
		print("~~~~~~~~~~~~DEBUG STATS~~~~~~~~~~~~")
		print("player hp: ", hp, "/", max_hp)
		print("player position: ", global_position)
		print("player velocity: ", velocity)
		print("move direction: ", move_direction)
		print("face direction: ", look_direction)
		print("total xp: ", total_xp)
		print("weapon xp: ", weapon_array.front().xp, "/", weapon_array.front().max_xp)
		print("weapon level: ", weapon_array.front().level)
		print("forgiveness timer time left: ", $ForgivenessTimer.time_left)
		print("snap vector: ", snap_vector)
		print("is on floor: ", is_on_floor())
		print("is in water: ", is_in_water)
		print("is on ladder: ", is_on_ladder)
		print("camera offset: ", $Camera2D.offset)
		print("camera position: ", $Camera2D.global_position)
		print("---")
		print("screen size: ", OS.get_screen_size())
		print("window size: ", OS.get_window_size())
		print("viewport size: ", get_tree().get_root().size)
		print("---")
		print("topics: ", topic_array)
		print("weapons: ", weapon_array)
		print("~~~~~~~~~~~~DEBUG STATS~~~~~~~~~~~~")

func debug_fly():
	if debug_active == false:
		print("debug fly: ON")
		debug_active = true
		invincible = true
		colliding = false
		$CollisionShape2D.disabled = true
		$HurtDetector.monitoring = false
		$ItemDetector.monitoring = false
	
	elif debug_active == true:
		print("debug fly: OFF")
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
