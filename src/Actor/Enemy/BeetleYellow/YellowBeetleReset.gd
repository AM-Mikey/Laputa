extends Node

var state_name = "Reset"

var beetle_actor

onready var reset_timer = $Timer

func physics_process():
	
	pass
	
func enter():
	beetle_actor.swap_direction_vector()
	beetle_actor.detection_raycast.cast_to = beetle_actor.direction_vector * beetle_actor.sight_distance
	if beetle_actor.is_on_floor():
		#use floor idle
		beetle_actor.animated_sprite.animation = "Idle_Floor"
		beetle_actor.animated_sprite.flip_v = false
		pass
	if beetle_actor.is_on_ceiling():
		beetle_actor.animated_sprite.animation = "Idle_Floor"
		#use ceiling idle
		beetle_actor.animated_sprite.flip_v = true
		pass
		
	if beetle_actor.is_on_wall():
		beetle_actor.animated_sprite.animation = "Idle_Wall"		
		#use wall idle
		pass
	reset_timer.start()
	pass
	
func exit():
	pass

func _on_Timer_timeout():
	beetle_actor.change_state(beetle_actor.idle_state)

