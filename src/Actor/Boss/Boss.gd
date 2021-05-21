extends Actor
class_name Boss, "res://assets/Icon/BossIcon.png"

const BLOOD = preload("res://src/Effect/EnemyBloodEffect.tscn")


var hp: int
var damage_on_contact: int



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
