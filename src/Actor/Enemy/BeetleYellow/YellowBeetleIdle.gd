extends Node

var state_name = "Idle"

var beetle_actor

onready var attack_timer = $Timer

func physics_process():
	var collision = beetle_actor.detection_raycast.get_collider()
	if collision != null && collision.is_in_group("Player"):
		#player detected.		
		#change state.
		beetle_actor.change_state(beetle_actor.attack_state)
		pass	
	pass
	
func enter():	
	pass
	
func exit():
	pass
