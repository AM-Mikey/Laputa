extends Area2D

var active_actor = null

func _on_Air_body_entered(body):
	active_actor = body
	active_actor.is_in_water = false
