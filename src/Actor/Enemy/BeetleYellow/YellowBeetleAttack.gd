extends Node

var state_name = "Attack"
var beetle_actor

func physics_process():
	#move in direction until wall is hit
	var velo = beetle_actor.move_and_slide(beetle_actor.direction_vector * beetle_actor.speed, Vector2.UP)
	if velo == Vector2.ZERO:
		#wall was hit
		beetle_actor.change_state(beetle_actor.reset_state)
	#once wall is hit change state to reset state
	pass
	
func enter():
	beetle_actor.animated_sprite.playing = true
	beetle_actor.animated_sprite.animation = state_name
	if beetle_actor.direction_vector == Vector2.RIGHT:
		beetle_actor.animated_sprite.flip_h = true
	else:
		beetle_actor.animated_sprite.flip_h = false
	pass
	
func exit():
	pass
