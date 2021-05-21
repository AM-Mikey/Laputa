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

export var drop_rolls: int = 1
export var small_hp_chance: float = .2
export var large_hp_chance: float = .1
export var small_xp_chance: float = .1
export var medium_xp_chance: float = .1
export var large_xp_chance: float = .1
export var small_ammo_chance: float = .2
export var large_ammo_chance: float = .1


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
		
		yield(get_tree().create_timer(5.0), "timeout") #free after 4 seconds to ensure that the drop was either picked up or has despawned
		print("removed enemy")
		queue_free()
	
	
func do_death_drop():
	var heart = HEART.instance()
	var xp = XP.instance()
	var ammo = AMMO.instance()
	
	rng.randomize()
	var drop = rng.randf()
	
	if drop > 0 and drop < small_hp_chance:
		get_parent().add_child(heart)
		heart.position = global_position
		var player = heart.get_node("AnimationPlayer")
		player.play("Small")
		yield(player, "animation_finished")
		heart.queue_free()

	elif drop > small_hp_chance and drop < small_hp_chance + large_hp_chance:
		get_parent().add_child(heart)
		heart.position = global_position
		var player = heart.get_node("AnimationPlayer")
		player.play("Large")
		yield(player, "animation_finished")
		heart.queue_free()

	elif drop > small_hp_chance + large_hp_chance and drop < small_hp_chance + large_hp_chance + small_xp_chance:
		get_parent().add_child(xp)
		xp.position = global_position
		var player = xp.get_node("AnimationPlayer")
		player.play("Small")
		yield(player, "animation_finished")
		xp.queue_free()
		
	elif drop > small_hp_chance + large_hp_chance + small_xp_chance and drop < small_hp_chance + large_hp_chance + small_xp_chance + medium_xp_chance:
		get_parent().add_child(xp)
		xp.position = global_position
		var player = xp.get_node("AnimationPlayer")
		player.play("Medium")
		yield(player, "animation_finished")
		xp.queue_free()
	elif drop > small_hp_chance + large_hp_chance + small_xp_chance + medium_xp_chance and drop < small_hp_chance + large_hp_chance + small_xp_chance + medium_xp_chance + large_xp_chance:
		get_parent().add_child(xp)
		xp.position = global_position
		var player = xp.get_node("AnimationPlayer")
		player.play("Large")
		yield(player, "animation_finished")
		xp.queue_free()
	elif drop > small_hp_chance + large_hp_chance + small_xp_chance + medium_xp_chance + large_xp_chance and drop < small_hp_chance + large_hp_chance + small_xp_chance + medium_xp_chance + large_xp_chance + small_ammo_chance:
		get_parent().add_child(ammo)
		ammo.position = global_position
		var player = ammo.get_node("AnimationPlayer")
		player.play("Small")
		yield(player, "animation_finished")
		ammo.queue_free()
	elif drop > small_hp_chance + large_hp_chance + small_xp_chance + medium_xp_chance + large_xp_chance + small_ammo_chance and drop < small_hp_chance + large_hp_chance + small_xp_chance + medium_xp_chance + large_xp_chance + small_ammo_chance + large_ammo_chance:
		get_parent().add_child(ammo)
		ammo.position = global_position
		var player = ammo.get_node("AnimationPlayer")
		player.play("Large")
		yield(player, "animation_finished")
		ammo.queue_free()
	else:
		pass

#func _input(event):
#	if event.is_action_pressed("debug"):
#		print("enemy hp in instance '", name, "' : ", hp)
