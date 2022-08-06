extends Actor
class_name Enemy, "res://assets/Icon/EnemyIcon.png"

#const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const AMMO = preload("res://src/Actor/Pickup/Ammo.tscn")
const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")
const EXPERIENCE = preload("res://src/Actor/Pickup/Experience.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const HEART = preload("res://src/Actor/Pickup/Heart.tscn")
const STATE_LABEL = preload("res://src/Utility/StateLabel.tscn")

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


onready var w = get_tree().get_root().get_node("World")
onready var pc = get_tree().get_root().get_node_or_null("World/Juniper")




func _ready():
	add_to_group("Enemies")
	if disabled: return

	if debug:
		add_child(STATE_LABEL.instance())
	
	if not is_in_group("EnemyPreviews"):
		yield(get_tree(), "idle_frame")
		if state != "" and state != null: #TODO: this prevents enemies from starting in a state if we dont yield? we get ton of errors if we dont because we delete the enemy when moving it
			change_state(state)
	
	if not w.get_node("EditorLayer").has_node("Editor"):
		setup()

func setup(): #EVERY ENEMY MUST HAVE
	pass #to be determined in enemy script. 



func disable():
#	if get("starting_state"):
#		change_state(get("starting_state"))
#	else: print("ERRRORRRRR NO STARTING STATE FOR ENEMY")
	disabled = true

func enable():
	disabled = false


func _physics_process(_delta):
	if disabled or dead: return
	
	if state != "":
		do_state()
	if debug:
		$StateLabel.text = state



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
	if disabled: return
	var do_method = "do_" + state
	if has_method(do_method):
		call(do_method)
	#else: printerr("ERROR: Enemy: " + name + " is missing state method with name: " + do_method)

func change_state(new):
	if disabled: return
	var exit_method = "exit_" + state
	if has_method(exit_method):
		call(exit_method)
	state = new
	var enter_method = "enter_" + state
	if has_method(enter_method):
		call(enter_method)


### DAMAGE/DEATH ###

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

### DAMAGE NUMBER ###

func setup_damagenum_timer():
	var timer = Timer.new()
	timer.one_shot = true
	timer.name = "DamagenumTimer"
	timer.connect("timeout", self, "_on_DamagenumTimer_timeout")
	add_child(timer)


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

### DEATH ###

func die():
	if dead: return
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
	if reward == 0:return
	
	var heart = HEART.instance()
	var ammo = AMMO.instance()
	
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
		heart.position = position
		match reward:
			1,2: heart.value = 2
			3,4,5: heart.value = 4
			6,7,8,9,10 : heart.value = 8
		world.middle.add_child(heart)
	
	elif drop > heart_chance and drop <= heart_chance + experience_chance: #drop xp
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

	else: #drop ammo
		ammo.position = position
		match reward:
			1,2: ammo.value = 0.2
			3,4,5,6,7,8,9,10: ammo.value = 0.5
		world.middle.add_child(ammo)
