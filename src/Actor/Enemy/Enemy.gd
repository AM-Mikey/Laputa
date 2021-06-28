extends Actor
class_name Enemy, "res://assets/Icon/EnemyIcon.png"

const EFFECT = preload("res://src/Effect/Effect.tscn")
const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")
const HEART = preload("res://src/Actor/ItemActor/Heart.tscn")
const EXPERIENCE = preload("res://src/Actor/ItemActor/Experience.tscn")
const AMMO = preload("res://src/Item/Ammo.tscn")

onready var player_actor = get_tree().get_root().get_node("World/Recruit")

var rng = RandomNumberGenerator.new()
var disabled = false
var protected = false

var hp: int
var damage_on_contact: int

var recent_damage_taken: int
var timer = Timer.new()
var damagenum_reset_time: float = 1.0

export var id: String
export var level = 1
export var heart_chance = 1
export var experience_chance = 1
export var ammo_chance = 1

var camera_forgiveness_distance = 64
var free_counter = 0

func _physics_process(delta):
	if not disabled and not protected:
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

func _ready():
	add_to_group("Enemies")
	timer.connect("timeout",self,"_on_timer_timeout") 
	add_child(timer)
	timer.one_shot = true
	timer.start(damagenum_reset_time)

func _on_timer_timeout():
	if not dead:
		if recent_damage_taken != 0:
			do_damage_num(recent_damage_taken)
			recent_damage_taken = 0
			timer.start(damagenum_reset_time)

func hit(damage, blood_direction):
	$PosHurt.play()
	hp -= damage
	var blood = BLOOD.instance()
	get_parent().add_child(blood)
	blood.global_position = global_position
	blood.direction = blood_direction
	#print(blood_direction)
	
	#if timer.is_stopped(): #if the reset time is over, then set recent damage to 0
		
	#timer.start(damagenum_reset_time) # and restart timer again either way
	recent_damage_taken += damage
	if hp <= 0:
		die()


func die():
	if not dead:
		dead = true
		do_death_drop()
		do_damage_num(recent_damage_taken)
		
		player_actor.is_in_enemy = false #THIS IS A BAD WAY TO DO THIS if a player is in a different enemy when this one dies, they will be immune to that enemy
		
		var effect = EFFECT.instance()
		get_parent().add_child(effect)
		effect.position = global_position
		
		var player = effect.get_node("AnimationPlayer")
		player.play("Explode")
		visible = false
		set_collision_layer_bit(1, false) #turn off the fact you are an enemy
		set_collision_mask_bit(0, false) #turn off checking for player
		#$CollisionShape2D.disabled = true #isnt doing anything for some reason
		yield(player, "animation_finished")
		effect.queue_free()
		if get_parent().get_parent() is Path2D:
			get_parent().get_parent().queue_free()
		else:
			queue_free()

	
func do_death_drop():
	var heart = HEART.instance()
	var experience = EXPERIENCE.instance()
	var ammo = AMMO.instance()
	
#	var ray = RayCast2D.new()
#	ray.set_collision_mask_bit(0, false)
#	ray.set_collision_mask_bit(3, true)
#	ray.cast_to = Vector2(0, 1000)
#	ray.enabled = true
#	add_child(ray)
#	yield(get_tree(), "idle_frame")
#	var tilemap = ray.get_collider()
#	ray.queue_free()
	
#	var target_pos = global_position
#	var local_pos = tilemap.to_local(target_pos)
#	var map_pos = tilemap.world_to_map(local_pos)
#	var target_cell = tilemap.get_cellv(map_pos)
#	while target_cell != -1: #while target cell is not air
#		map_pos.y -=1
#		target_cell = tilemap.get_cellv(map_pos)
#	local_pos = tilemap.map_to_world(map_pos)
#	target_pos = tilemap.to_global(local_pos)


	var total_chance = heart_chance + experience_chance + ammo_chance
	rng.randomize()
	var drop = rng.randf_range(0, total_chance)
	
	if drop <= heart_chance:
		heart.position = position
		match level:
			0,1,2: heart.value = 2
			3,4,5: heart.value = 4
			6,7,8,9,10 : heart.value = 8
		get_tree().get_current_scene().add_child(heart)
	elif drop > heart_chance and drop <= heart_chance + experience_chance:
		experience.position = position
		match level:
			0,1:
				experience.value = 1
				get_tree().get_current_scene().add_child(experience)
			2:
				experience.value = 1
				get_tree().get_current_scene().add_child(experience)
				get_tree().get_current_scene().add_child(experience)
			3:
				experience.value = 3
				get_tree().get_current_scene().add_child(experience)
			4:
				experience.value = 4
				get_tree().get_current_scene().add_child(experience)

	else:
		ammo.position = position
		match level:
			0,1,2: ammo.value = 0.2
			3,4,5,6,7,8,9,10: ammo.value = 0.5
		get_tree().get_current_scene().add_child(ammo)
