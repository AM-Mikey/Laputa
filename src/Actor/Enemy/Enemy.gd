extends Actor
class_name Enemy, "res://assets/Icon/EnemyIcon.png"

#const DAMAGENUMBER = preload("res://src/Effect/DamageNumber.tscn")
const EXPLOSION = preload("res://src/Effect/Explosion.tscn")
const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")
const HEART = preload("res://src/Actor/Pickup/Heart.tscn")
const EXPERIENCE = preload("res://src/Actor/Pickup/Experience.tscn")
const AMMO = preload("res://src/Actor/Pickup/Ammo.tscn")



var rng = RandomNumberGenerator.new()
var disabled = false
var protected = false
export var debug = false

var hp: int
var damage_on_contact: int

var damagenum = null
var damagenum_time: float = 0.5

export var id: String
var level = 1


var heart_chance = 1
var experience_chance = 3
var ammo_chance = 1

var camera_forgiveness_distance = 64
var free_counter = 0

onready var player_actor = get_tree().get_root().get_node_or_null("World/Juniper")



func _ready():
	add_to_group("Enemies")

	var timer = Timer.new()
	timer.one_shot = true
	timer.name = "DamagenumTimer"
	timer.connect("timeout", self, "_on_DamagenumTimer_timeout")
	add_child(timer)


func _physics_process(_delta):
	if not disabled and not protected and hp == 99999999999: #never do for now
		var camera_limiters = get_tree().get_nodes_in_group("CameraLimiters")
		var left
		var right
		var top
		var bottom
		for c in camera_limiters:
			left = c.get_node("Left").global_position.x
			right = c.get_node("Right").global_position.x
			top = c.get_node("Top").global_position.y
			bottom = c.get_node("Bottom").global_position.y
		
		if global_position.x < left - camera_forgiveness_distance:
			free_counter +=1
		elif global_position.x > right + camera_forgiveness_distance:
			free_counter +=1
		elif global_position.y < top - camera_forgiveness_distance:
			free_counter +=1
		elif global_position.y > bottom + camera_forgiveness_distance:
			free_counter +=1
		
		if free_counter > 0:
			print("enemy left camera limits, freeing")
			if get_parent().get_parent() is Path2D:
				get_parent().get_parent().free()
			else:
				free()



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
	if damagenum == null: #if we dont already have a damage number create a new one
		damagenum = DAMAGENUMBER.instance()
		damagenum.value = damage
		$DamagenumTimer.start(damagenum_time)
		
	else: #add time and add values
		damagenum.value += damage
		$DamagenumTimer.start($DamagenumTimer.time_left + damagenum_time)
		
		

func _on_DamagenumTimer_timeout():
		damagenum.position = global_position
		get_tree().get_root().get_node("World/Front").add_child(damagenum)
		damagenum = null

func die():
	if not dead:
		dead = true
		do_death_drop()
		$DamagenumTimer.stop()
		_on_DamagenumTimer_timeout()
		if player_actor == null:
			player_actor = get_tree().get_root().get_node_or_null("World/Juniper")
			player_actor.enemies_touched.erase(self)
		
		var explosion = EXPLOSION.instance()
		get_tree().get_root().get_node("World/Front").add_child(explosion)
		explosion.position = global_position
		
		if get_parent().get_parent() is Path2D:
			get_parent().get_parent().queue_free()
		else:
			queue_free()
	
	
func do_death_drop():
	var heart = HEART.instance()
	var ammo = AMMO.instance()
	
	var player_needs_ammo = false
	for w in player_actor.get_node("GunManager/Guns").get_children():
		if w.ammo < w.max_ammo:
			player_needs_ammo = true
	
	if not player_needs_ammo:
		ammo_chance = 0
	
	if level == 0:
		return

	var total_chance = heart_chance + experience_chance + ammo_chance
	rng.randomize()
	var drop = rng.randf_range(0, total_chance)
	
	if drop <= heart_chance:
		heart.position = position
		match level:
			1,2: heart.value = 2
			3,4,5: heart.value = 4
			6,7,8,9,10 : heart.value = 8
		get_tree().get_root().get_node("World/Middle").add_child(heart)
	elif drop > heart_chance and drop <= heart_chance + experience_chance:

		var loop_times = 1
		var value = 1
		
		match level:
			1:
				pass
			2:
				loop_times = 2
			3:
				loop_times = 3
			4:
				loop_times = 4
			5:
				value = 5

		while loop_times > 0:
			var experience = EXPERIENCE.instance()
			experience.value = value
			experience.position = position
			get_tree().get_root().get_node("World/Middle").add_child(experience)
			loop_times -= 1

	else:
		ammo.position = position
		match level:
			1,2: ammo.value = 0.2
			3,4,5,6,7,8,9,10: ammo.value = 0.5
		get_tree().get_root().get_node("World/Middle").add_child(ammo)
