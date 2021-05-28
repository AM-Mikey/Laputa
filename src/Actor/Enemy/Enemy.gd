extends Actor
class_name Enemy, "res://assets/Icon/EnemyIcon.png"

const EFFECT = preload("res://src/Effect/Effect.tscn")
const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")
const HEART = preload("res://src/Item/Heart.tscn")
const XP = preload("res://src/Actor/Xp.tscn")
const AMMO = preload("res://src/Item/Ammo.tscn")

onready var player_actor = get_tree().get_root().get_node("World/Recruit")

var rng = RandomNumberGenerator.new()

export var heart_drop_percent = 90

var hp: int
var damage_on_contact: int

var recent_damage_taken: int
var timer = Timer.new()
export var damagenum_reset_time: float = 1.0

export var level = 1
export var hp_chance = 10
export var xp_chance = 0
export var ammo_chance = 0

func _ready():
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
		queue_free()

	
func do_death_drop():
	var heart = HEART.instance()
	var xp = XP.instance()
	var ammo = AMMO.instance()
	
	var ray = RayCast2D.new()
	ray.set_collision_mask_bit(0, false)
	ray.set_collision_mask_bit(3, true)
	ray.cast_to = Vector2(0, 1000)
	ray.enabled = true
	add_child(ray)
	yield(get_tree(), "idle_frame")
	var tilemap = ray.get_collider()
	ray.queue_free()
	
	var target_pos = global_position
	var local_pos = tilemap.to_local(target_pos)
	var map_pos = tilemap.world_to_map(local_pos)
	var target_cell = tilemap.get_cellv(map_pos)
	while target_cell != -1: #while target cell is not air
		map_pos.y -=1
		target_cell = tilemap.get_cellv(map_pos)
	local_pos = tilemap.map_to_world(map_pos)
	target_pos = tilemap.to_global(local_pos)


	var total_chance = hp_chance + xp_chance + ammo_chance
	rng.randomize()
	var drop = rng.randf_range(0, total_chance)
	
	if drop <= hp_chance:
		get_tree().get_current_scene().add_child(heart)
		heart.position = target_pos
		heart.value = level
	elif drop > hp_chance and drop <= hp_chance + xp_chance:
		get_tree().get_current_scene().add_child(xp)
		xp.position = target_pos
		xp.value = level
	else:
		get_tree().get_current_scene().add_child(ammo)
		ammo.position = target_pos
		ammo.value = float(level)/10
