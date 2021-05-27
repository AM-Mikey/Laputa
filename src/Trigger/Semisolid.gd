extends Area2D

var active_player = null
var has_player_near = false

func _on_SemiSolid_body_entered(body):
	active_player = body
	has_player_near = true

func _on_SemiSolid_body_exited(body):
	has_player_near = false

func _process(delta):
	if active_player != null:
		if has_player_near:
			active_player.can_fall_through = true
		else:
			active_player.can_fall_through = false
			active_player = null
