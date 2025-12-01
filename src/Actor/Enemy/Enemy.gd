@icon("res://assets/Icon/EnemyIcon.png")
extends Actor
class_name Enemy

const AMMO = preload("res://src/Actor/Pickup/Ammo.tscn")
const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")
const EXPERIENCE = preload("res://src/Actor/Pickup/Experience.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const HEART = preload("res://src/Actor/Pickup/Heart.tscn")
const STATE_LABEL = preload("res://src/Utility/StateLabel.tscn")

var state: String

var disabled = false
var protected = false
@export var debug = false

var hp: int
var damage_on_contact: int
var enemy_damage_on_contact: int
var hit_enemies_on_contact = false
var hurt_sound = "enemy_hurt"
var die_sound = "enemy_die"
var damage_number = null
var just_spawned = true

@export var id: String

var reward = 1
var heart_chance = 1
var experience_chance = 3
var ammo_chance = 1


@onready var w = get_tree().get_root().get_node("World")
@onready var pc = get_tree().get_root().get_node_or_null("World/Juniper")




func _ready():
	home = global_position

	if disabled: return

	var state_label = STATE_LABEL.instantiate()
	add_child(state_label)
	state_label.visible = debug
	safe_margin = 0.001

	#if not is_in_group("EnemyPreviews"): #this was causing issues with waiting a frame for setup(), just start state in setup()
		#await get_tree().process_frame
		#if state != "" and state != null: #TODO: this prevents enemies from starting in a state if we dont yield? we get ton of errors if we dont because we delete the enemy when moving it
			#change_state(state)

	setup()
	await get_tree().physics_frame
	await get_tree().physics_frame
	just_spawned = false

func setup(): #EVERY ENEMY MUST HAVE
	pass #to be determined in enemy script.



func disable():
	disabled = true

func enable():
	disabled = false

func _physics_process(delta):
	if disabled or dead: return
	if state != "":
		do_state()
	if has_node("StateLabel"):
		get_node("StateLabel").text = state
	_on_physics_process(delta)

func _on_physics_process(delta): #for child
	pass

#func exit():	#OBSOLETE
	#if get_parent().get_parent() is Path2D:
		#get_parent().get_parent().queue_free()
	#else:
		#queue_free()

func calc_velocity(velocity: Vector2, move_dir, speed, do_gravity = true, do_acceleration = true, do_friction = true) -> Vector2:
	var out: = velocity
	var fractional_speed = speed
	if is_in_water:
		fractional_speed = speed * Vector2(0.666, 0.666)
	#X
	if do_acceleration:
		if move_dir.x != 0:
			out.x = min(abs(out.x) + acceleration, fractional_speed.x)
			out.x *= move_dir.x
		elif do_friction:
			if is_on_floor():
				out.x = lerp(out.x, 0.0, ground_cof)
			else:
				out.x = lerp(out.x, 0.0, air_cof)
	else: #no acceleration
		out.x = fractional_speed.x * move_dir.x

	#Y
	if do_gravity:
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = fractional_speed.y * move_dir.y
	else:
		out.y = fractional_speed.y * move_dir.y
	return out


### STATES ###

func do_state():
	if disabled: return
	var do_method = "do_" + state
	if has_method(do_method):
		call(do_method)
	#else: printerr("ERROR: Enemy: " + name + " is missing state method with name: " + do_method)

func change_state(new):
	if disabled: return
	if has_node("StateTimer"): #this prevents previous states using the same timer from triggering things
		get_node("StateTimer").stop()
	var exit_method = "exit_" + state
	if has_method(exit_method):
		call(exit_method)
	state = new
	var enter_method = "enter_" + state
	if has_method(enter_method):
		call(enter_method)



### DAMAGE/DEATH ###

func hit(damage, blood_direction):
	_on_hit(damage, blood_direction)
	hp -= damage
	var blood = BLOOD.instantiate()
	get_tree().get_root().get_node("World/Front").add_child(blood)
	blood.global_position = $Sprite2D.global_position #more accurate for visual
	blood.direction = blood_direction

	set_damagenum(damage)

	if hp <= 0:
		die()
	else:
		am.play(hurt_sound, self)

func _on_hit(damage, blood_direction): #inhereted for enemies to do something on hit
	pass


### DAMAGE NUMBER ###

func set_damagenum(damage):
	var enabled_col_shapes = []
	for c in get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			if c.disabled == false:
				enabled_col_shapes.append(c)
	var good_collision_shape = enabled_col_shapes.front()
	var y_offset = good_collision_shape.shape.get_rect().position.y - (good_collision_shape.shape.get_rect().size.y / 2.0) #Warning! this assumes that the rect2 is always centered

	if damage_number == null:
		damage_number = DAMAGE_NUMBER.instantiate()
		damage_number.value = damage
		damage_number.position = global_position
		damage_number.position.y += y_offset
		get_tree().get_root().get_node("World/Front").add_child(damage_number)
	else: #add time and add values
		damage_number.value += damage
		damage_number.reset()


### DEATH ###

func die(quietly = false):
	if dead: return
	dead = true
	if !pc:
		pc = get_tree().get_root().get_node_or_null("World/Juniper")
	if pc:
		pc.enemies_touching.erase(self)
	if !quietly:
		am.play(die_sound, self)
		do_death_routine()
		do_death_drop()
		var explosion = EXPLOSION.instantiate()
		explosion.position = $Sprite2D.global_position #more accurate for visual
		world.front.add_child(explosion)
	queue_free()

func do_death_routine(): #shadow this for individual enemies ##note this doesnt wait for the function to finish, so anything that requires await will be cut short
	pass

func do_death_drop():
	if reward == 0:return

	var heart = HEART.instantiate()
	var ammo = AMMO.instantiate()

	#ammo chance
	var player_needs_ammo = false
	for w in pc.get_node("GunManager/Guns").get_children():
		if w.ammo < w.max_ammo:
			player_needs_ammo = true
	if not player_needs_ammo:
		ammo_chance = 0



	var total_chance = heart_chance + experience_chance + ammo_chance
	rng.randomize()
	var drop = rng.randf_range(0, total_chance)

	if drop <= heart_chance: # drop hp
		heart.position = global_position
		match reward:
			1,2: heart.value = 2
			3,4,5: heart.value = 4
			6,7,8,9,10 : heart.value = 8
		world.middle.call_deferred("add_child", heart)

	elif drop > heart_chance and drop <= heart_chance + experience_chance: #drop xp
		var values = [1]

		match reward:
			1: pass
			2: values = [1,1]
			3: values = [1,1,1]
			4: values = [1,1,1,1]
			5: values = [5]
			6: values = [5,1]
			7: values = [5,1,1]
			8: values = [5,1,1,1]
			9: values = [5,1,1,1,1]
			10: values = [10]

		for v in values:
			var experience = EXPERIENCE.instantiate()
			experience.value = v
			experience.position = global_position
			world.middle.call_deferred("add_child", experience)

	else: #drop ammo
		ammo.position = global_position
		match reward:
			1,2: ammo.value = 0.2
			3,4,5,6,7,8,9,10: ammo.value = 0.5
		world.middle.call_deferred("add_child", ammo)



### SIGNALS ###

func _on_hitbox_area_entered(area):
	if area.get_collision_layer_value(17): #playerhurt
		area.get_parent().enemy_entered(self)
	elif area.get_collision_layer_value(18) and hit_enemies_on_contact == true: #do they need iframes?
		if area.get_parent() != self:
			var enemy_damage = damage_on_contact
			if enemy_damage_on_contact:
				enemy_damage = enemy_damage_on_contact
			area.get_parent().hit(enemy_damage, Vector2(area.global_position - global_position).normalized())

func _on_hitbox_area_exited(area):
	if area.get_collision_layer_value(17): #playerhurt
		area.get_parent().enemy_exited(self)
	#elif area.get_collision_layer(18) and hit_enemies_on_contact == true:
