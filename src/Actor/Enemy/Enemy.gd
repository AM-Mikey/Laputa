extends Actor
class_name Enemy, "res://assets/Icon/EnemyIcon.png"

#const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")
const HEART = preload("res://src/Actor/Pickup/Heart.tscn")
const EXPERIENCE = preload("res://src/Actor/Pickup/Experience.tscn")
const AMMO = preload("res://src/Actor/Pickup/Ammo.tscn")

var state: String 

var disabled = false
var protected = false
export var debug = false

var hp: int
var damage_on_contact: int

var damagenum = null
var damagenum_time: float = 0.5

export var id: String
var reward = 1


var heart_chance = 1
var experience_chance = 3
var ammo_chance = 1

var camera_forgiveness_distance = 64
var free_counter = 0

onready var pc = get_tree().get_root().get_node_or_null("World/Juniper")



func _ready():
	add_to_group("Enemies")

	var timer = Timer.new()
	timer.one_shot = true
	timer.name = "DamagenumTimer"
	timer.connect("timeout", self, "_on_DamagenumTimer_timeout")
	add_child(timer)
	
	if not is_in_group("EnemyPreviews"):
		yield(get_tree(), "idle_frame")
		if state != "": #TODO: this prevents enemies from starting in a state if we dont yield? we get ton of errors if we dont because we delete the enemy when moving it
			change_state(state)
	

func disable():
	disabled = true

func enable():
	disabled = false


func _physics_process(_delta):
	if disabled or dead:
		return
	if state != "":
		do_state()




func exit():
	if get_parent().get_parent() is Path2D:
		get_parent().get_parent().queue_free()
	else:
		queue_free()

func get_velocity(velocity: Vector2, move_dir, speed, do_gravity = true) -> Vector2:
	var out: = velocity
	out.x = speed.x * move_dir.x
	if do_gravity:
		out.y += gravity * get_physics_process_delta_time()
		if move_dir.y < 0:
			out.y = speed.y * move_dir.y
	else:
		out.y = speed.y * move_dir.y
	return out


### STATES ###

func do_state():
	var do_method = "do_" + state
	if has_method(do_method):
		call(do_method)
	#else: printerr("ERROR: Enemy: " + name + " is missing state method with name: " + do_method)

func change_state(new):
	var exit_method = "exit_" + state
	if has_method(exit_method):
		call(exit_method)
	state = new
	var enter_method = "enter_" + state
	if has_method(enter_method):
		call(enter_method)


func hit(damage, blood_direction):
	hp -= damage
	var blood = BLOOD.instance()
	get_tree().get_root().get_node("World/Front").add_child(blood)
	blood.global_position = global_position
	blood.direction = blood_direction

	prepare_damagenum(damage)
	
	if hp <= 0:
		die()
	else:
		am.play_pos("enemy_hurt", self) #TODO: different hit sounds per enemy


func prepare_damagenum(damage):
	if not damagenum: #if we dont already have a damage number create a new one
		damagenum = DAMAGENUMBER.instance()
		damagenum.value = damage
		$DamagenumTimer.start(damagenum_time)
	else: #add time and add values
		damagenum.value += damage
		$DamagenumTimer.start($DamagenumTimer.time_left)

func _on_DamagenumTimer_timeout():
		damagenum.position = global_position
		world.front.add_child(damagenum)
		damagenum = null

func die():
	if not dead:
		dead = true
		do_death_drop()
		$DamagenumTimer.stop()
		_on_DamagenumTimer_timeout()
		if not pc:
			pc = get_tree().get_root().get_node_or_null("World/Juniper")
			pc.enemies_touched.erase(self)
		var explosion = EXPLOSION.instance()
		explosion.position = global_position
		world.front.add_child(explosion)
		exit()


func do_death_drop():
	var heart = HEART.instance()
	var ammo = AMMO.instance()
	
	var player_needs_ammo = false
	for w in pc.get_node("GunManager/Guns").get_children():
		if w.ammo < w.max_ammo:
			player_needs_ammo = true
	
	if not player_needs_ammo:
		ammo_chance = 0
	
	if reward == 0:
		return

	var total_chance = heart_chance + experience_chance + ammo_chance
	rng.randomize()
	var drop = rng.randf_range(0, total_chance)
	
	if drop <= heart_chance:
		heart.position = position
		match reward:
			1,2: heart.value = 2
			3,4,5: heart.value = 4
			6,7,8,9,10 : heart.value = 8
		world.middle.add_child(heart)
	elif drop > heart_chance and drop <= heart_chance + experience_chance:

		var loop_times = 1
		var value = 1
		
		match reward:
			1: pass
			2: loop_times = 2
			3: loop_times = 3
			4: loop_times = 4
			5: value = 5

		while loop_times > 0:
			var experience = EXPERIENCE.instance()
			experience.value = value
			experience.position = position
			world.middle.add_child(experience)
			loop_times -= 1

	else:
		ammo.position = position
		match reward:
			1,2: ammo.value = 0.2
			3,4,5,6,7,8,9,10: ammo.value = 0.5
		world.middle.add_child(ammo)

#func check_camera_limits():
#	var c = get_tree().get_nodes_in_group("CameraLimiters")[0] #pulls the first limiter
#	var left = c.get_node("Left").global_position.x
#	var right = c.get_node("Right").global_position.x
#	var top = c.get_node("Top").global_position.y
#	var bottom = c.get_node("Bottom").global_position.y
#
#	if global_position.x < left - camera_forgiveness_distance:
#		exit()
#	elif global_position.x > right + camera_forgiveness_distance:
#		exit()
#	elif global_position.y < top - camera_forgiveness_distance:
#		exit()
#	elif global_position.y > bottom + camera_forgiveness_distance:
#		exit()
