@icon("res://assets/Icon/BossIcon.png")
extends Actor
class_name Boss

const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")

#signal setup_ui(display_name, hp, max_hp)
#signal health_updated(hp)

var display_name: String
var hp: int
var max_hp: int
var damage_on_contact: int
var recent_damage_taken: int

@onready var hud = get_tree().get_root().get_node("World/UILayer/HUD")

#func _ready():
	#hud.get_node("Boss").visible = true
	
#	connect("setup_ui", hud, "_on_boss_setup_ui")
#	connect("health_updated", hud, "_on_boss_health_updated")

func hit(damage, blood_direction):
	#emit_signal("health_updated", hp)
	$PosHurt.play()
	hp -= damage
	var blood = BLOOD.instantiate()
	for l in get_tree().get_nodes_in_group("Levels"):
		world.get_node("Front").add_child(blood)
	blood.global_position = global_position
	blood.direction = blood_direction
	#print(blood_direction)
	
	#if timer.is_stopped(): #if the reset time is over, then set recent damage to 0
		
	#timer.start(damagenum_reset_time) # and restart timer again either way
	recent_damage_taken += damage
	if hp <= 0:
		die()


func die():
	#hud.get_node("Boss").visible = false
	queue_free()
