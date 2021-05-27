extends Area2D

var active_player = null

func _on_Water_body_entered(body):
	active_player = body
	active_player.is_in_water = true
