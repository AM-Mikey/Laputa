extends Node

var state_name = "Idle"

var beetle_actor

func physics_process():

	pass
	
func enter():
	$Timer.start()
	pass
	
func exit():
	pass


func _on_Timer_timeout():
	beetle_actor.change_state(beetle_actor.attack_state)
