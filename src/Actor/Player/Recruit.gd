extends Player

const POPUP = preload("res://src/UI/PopupText.tscn")
const LEVELUP = preload("res://src/Effect/LevelUp.tscn")
const LEVELDOWN = preload("res://src/Effect/LevelDown.tscn")

const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 4.0

var sfx_get_heart = load("res://assets/SFX/Placeholder/snd_health_refill.ogg")
var sfx_get_xp = load("res://assets/SFX/Placeholder/snd_get_xp.ogg")
var sfx_get_ammo = load("res://assets/SFX/Placeholder/snd_get_missile.ogg")

#export var speed.x = 90 #was 82.5 for a max gap of 7 (barely)
#var half_speed.x = speed.x/2
#export var speed.y = 180 #was 195 for 4 blocks
#export var normal_speed.y = 195
#export var long_speed.y = 150



export var minimum_jump_time = 0.0000000001 #was 0.1
export var minimum_direction_time = 1.0 #was 0.5  #scrapped idea where cave story forces you to jump a certain x distance when going max speed before jumping
var jump_starting_move_dir_x: int



export var min_xvelocity = 0.001


var direction_lock = Vector2.ZERO
var starting_direction #for acceleration
var bonk_distance = 4



export var hp: int = 100
export var max_hp: int = 100
var total_xp: int = 0


#STATES
var movement_profile = "sigma"
var jump_type: String #still supported?

var invincible = false
var colliding = true
var disabled = false

var is_in_enemy = false
var is_on_ladder = false
var is_on_ssp = false
var is_in_spikes = false

var debug_flying = false
export var debug_fly_speed = 500

var inventory: Array
var topic_array: Array = ["ham", "cheese", "marbles", "balogna"]
var weapon_array: Array = [load("res://src/Weapon/Revolver1.tres"), load("res://src/Weapon/GrenadeLauncher1.tres"), load("res://src/Weapon/MachinePistol1.tres"), load("res://src/Weapon/Shotgun1.tres")]

var move_dir = Vector2.LEFT
var face_dir = Vector2.LEFT
var shoot_dir = Vector2.LEFT

var snap_vector = SNAP_DIRECTION * SNAP_LENGTH

export var dodge_speed = Vector2(700, 100)
export var dodge_time: float = (0.3)

export var forgiveness_time = 0.05
var knockback = false
var knockback_direction: Vector2


export var knockback_speed = Vector2(80, 100)
var knockbackvelocity = Vector2.ZERO




onready var world = get_tree().get_root().get_node("World")

func _ready():
	speed = Vector2(90,100)
	
	var item_menu = get_tree().get_root().get_node("World/UILayer/ItemMenu")
	connect("inventory_updated", item_menu, "_on_inventory_updated")
	acceleration = 2.5 #was 5
	ground_cof = 0.1 #was 0.2
	air_cof = 0.00 # was 0.05
	
	$BonkTimeout.start(0.4)
	
	if weapon_array.front() != null:
		$WeaponSprite.texture = weapon_array.front().texture

func _physics_process(delta):
	#print("Velocity: ", velocity)
	if disabled != true:
		if colliding == true: #skip this entire thing if we're in debug mode
			
			var is_jump_interrupted = false
			if $MinimumJumpTimer.time_left == 0 and velocity.y < 0.0:
				if not Input.is_action_pressed("jump"):
					is_jump_interrupted = true
				
				
			move_dir = get_move_dir()

			
			if is_on_ceiling():
				if $BonkTimeout.time_left == 0:
					$BonkTimeout.start(0.4)
					var collision = get_slide_collision(0)
					print("collision normal:", collision.normal)
					var bonk = load("res://src/Effect/BonkParticle.tscn").instance()
					var bonk_position = position
					bonk_position.y -= 16
					bonk.position = bonk_position
					bonk.normal = collision.normal
					bonk.type = "bonk"
					get_tree().get_root().get_node("World/Front").add_child(bonk)
				
			
			if is_on_floor():
				jump_type = ""
#				speed.y = normal_speed.y
					
				if not knockback and not is_on_ladder:
					snap_vector = SNAP_DIRECTION * SNAP_LENGTH
				else: 
					snap_vector = Vector2.ZERO
				
				if $ForgivenessTimer.time_left == 0: #just landed
					if $BonkTimeout.time_left == 0:
						$BonkTimeout.start(0.4)
						var collision = get_slide_collision(get_slide_count() - 1)
						print("collision normal:", collision.normal)
						var bonk = load("res://src/Effect/BonkParticle.tscn").instance()
						bonk.position = position
						bonk.normal = collision.normal
						bonk.type = "land"
						get_tree().get_root().get_node("World/Front").add_child(bonk)
			
				if is_on_ladder:
					if Input.is_action_pressed("look_down"):
						is_on_ladder = false


				$ForgivenessTimer.start(forgiveness_time) #start forgiveness timer on any frame they're on the ground




			
			
			
			if Input.is_action_just_pressed("jump") and $ForgivenessTimer.time_left > 0 or Input.is_action_just_pressed("jump") and is_on_floor():
				$MinimumJumpTimer.start(minimum_jump_time)
				if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
					if abs(velocity.x) > 82: #since 82.5 is max x velocity, only count as a running jump then   ##Running JUMP CHECKING HERE
						jump_type = "running_jump"
#						speed.y = long_speed.y
						jump_starting_move_dir_x = move_dir.x
						$MinimumDirectionTimer.start(minimum_direction_time)
				snap_vector = Vector2.ZERO
				
#				if get_floorvelocity().y < 0: #borrowed this code to prevent sticking
#					position.y += get_floorvelocity().y * get_physics_process_delta_time() - gravity * get_physics_process_delta_time() - 1
				
				$JumpSound.play()
		
			
			#fall through ssp code
			if Input.is_action_just_pressed("look_down") and is_on_ssp and is_on_floor():
				position.y += 8
				
			if knockback:
				if knockbackvelocity == Vector2.ZERO:
					knockbackvelocity = Vector2(knockback_speed.x * knockback_direction.x, knockback_speed.y * -1)
					velocity.y = knockbackvelocity.y #set knockback y to this ONCE
				
				velocity.x += knockbackvelocity.x
				#print("velocity: ", velocity)
				#print("knockback velocity: ", knockbackvelocity)
				knockbackvelocity.x /= 2
				
				if abs(knockbackvelocity.x) < 1:
					knockbackvelocity = Vector2.ZERO
					knockback = false

			velocity = get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted)
			var new_velocity = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, true)
			
			if is_on_wall():
				new_velocity.y = max(velocity.y, new_velocity.y)
			
			velocity.y = new_velocity.y #only set y portion because we're doing move and slide with snap
			
#			$AnimationManager.run_anim_speed = max((abs(velocity.x)/speed.x) * 1.5, 0.1) #run_anim_speed = max((abs(velocity.x)/speed.x) * 1.5, 0.5)
#			#print(run_anim_speed)
#			$AnimationManager.animate(move_dir, velocity)
			

			if Input.is_action_just_pressed("fire_automatic"): 
				direction_lock = face_dir
			if Input.is_action_just_released("fire_automatic"): 
				direction_lock = Vector2.ZERO


			debug_print(move_dir, face_dir)
		
		else: #debug mode is on
			var move_dir = Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"), 
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))
			velocity = Vector2(
			debug_fly_speed * move_dir.x,
			debug_fly_speed * move_dir.y)
			velocity = move_and_slide(velocity, FLOOR_NORMAL, true)

	else: #we are curently disabled
		pass

func get_move_dir() -> Vector2:
	if is_on_ladder:
		return Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
			)
	else:
		return Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			
			-1.0 if Input.is_action_just_pressed("jump") and $ForgivenessTimer.time_left > 0 or Input.is_action_just_pressed("jump") and is_on_floor() 
			else 0.0)

func get_move_velocity(velocity, move_dir, face_dir, is_jump_interrupted) -> Vector2:
	var out = velocity
	
	var friction = false
	
	if is_on_ladder:
		out.y = move_dir.y * speed.y/2

		out.x = 0
		if Input.is_action_just_pressed("jump"):
			is_on_ladder = false
			out.y = speed.y * -1.0
	
	elif is_in_water:
		out.y += (gravity/2) * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = (speed.y * 0.75) * move_dir.y
		if is_jump_interrupted:
			out.y += (gravity/2) * get_physics_process_delta_time()
		
		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, (speed.x/2))
			out.x *= move_dir.x
		else:
			friction = true

	elif jump_type == "running_jump":
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = speed.y * move_dir.y
		if is_jump_interrupted:
			out.y += gravity * get_physics_process_delta_time()
		
		if move_dir.x == jump_starting_move_dir_x *-1: #if we turn around, cancel minimumdirectiontimer
			$MinimumDirectionTimer.stop()
		
		if not $MinimumDirectionTimer.is_stopped(): #still doing minimum x movement in jump #
			#print("still doing minimum x movement")
			out.x = speed.x
			out.x *= jump_starting_move_dir_x
		
		
		elif move_dir.x != 0: #try this as an "if" instead, if it's not working
			if move_dir.x != jump_starting_move_dir_x:
				out.x = min(abs(out.x) + acceleration, (speed.x * 0.5))
				out.x *= move_dir.x
				#$MinimumDirectionTimer.start(0)
			else:
				out.x = min(abs(out.x) + acceleration, speed.x)
				out.x *= move_dir.x
		else:
			friction = true
		
	
	else:
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = speed.y * move_dir.y
		if is_jump_interrupted:
			out.y += gravity * get_physics_process_delta_time()

		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, speed.x)
			out.x *= move_dir.x
		else:
			friction = true



	if is_on_floor():
		if friction == true:
			out.x = lerp(out.x, 0, ground_cof)
	else:
		if friction == true:
			out.x = lerp(out.x, 0, air_cof)


	if abs(out.x) < min_xvelocity:
		out.x = 0
	#print(out)
	return out


func _input(event):
	if not disabled:
		if event.is_action_pressed("movement_profile"):
			if movement_profile == "sigma":
				movement_profile = "mu"
				
				speed.x = 82.5
				speed.y = 180
				
				acceleration = 5
				ground_cof = 0.2
				air_cof = 0.05
				
			elif movement_profile == "mu":
				movement_profile = "chi"
				
				speed.x = 90
				speed.y = 180
				
				acceleration = 2.5
				ground_cof = 0.1
				air_cof = 0.05
			
			elif movement_profile == "chi":
				movement_profile = "sigma"
				
				speed.x = 90
				speed.y = 180
				
				acceleration = 2.5
				ground_cof = 0.1
				air_cof = 0.00
			
			yield(get_tree(), "idle_frame")
			var popup = POPUP.instance()
			popup.text = "movement profile: " + movement_profile
			world.get_node("UILayer").add_child(popup)



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


func _on_SSPDetector_body_entered(body):
	is_on_ssp = true


func _on_SSPDetector_body_exited(body):
	is_on_ssp = false
	
	
	
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
		print("camera offset: ", $PlayerCamera.offset)
		print("camera position: ", $PlayerCamera.global_position)
		print("---")
		print("screen size: ", OS.get_screen_size())
		print("window size: ", OS.get_window_size())
		print("viewport size: ", get_tree().get_root().size)
		print("---")
		print("topics: ", topic_array)
		print("weapons: ", weapon_array)
		print("~~~~~~~~~~~~DEBUG STATS~~~~~~~~~~~~")


func debug_fly():
	if not debug_flying:
		print("debug fly: ON")
		debug_flying = true
		invincible = true
		colliding = false
		$CollisionShape2D.disabled = true
		$HurtDetector.monitoring = false
		$ItemDetector.monitoring = false	
	else:
		print("debug fly: OFF")
		is_in_water = false
		is_on_ladder = false
		debug_flying = false
		invincible = false
		colliding = true
		$CollisionShape2D.disabled = false
		$HurtDetector.monitoring = true
		$ItemDetector.monitoring = true
		
		
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
			


#TODO clean these up and get rid of them 

func restore_hp():
	$PickupSound.stream = sfx_get_heart
	$PickupSound.play()
	hp = max_hp
	update_hp()
	
func update_inventory():
	emit_signal("inventory_updated", inventory)

func update_hp():
	HUD.update_hp()

func update_xp():
	HUD.update_xp(true)

func update_ammo():
	HUD.update_ammo()

func update_weapon():
	$WeaponManager.update_weapon()



