extends Area2D

var active_player = null
var has_player_near = false

func _on_Ladder_body_entered(body):
	active_player = body
	has_player_near = true

func _on_Ladder_body_exited(body):
	active_player.is_on_ladder = false
	has_player_near = false


func _input(event):
	if event.is_action_pressed("look_up") and has_player_near or event.is_action_pressed("look_down") and has_player_near:
		active_player.is_on_ladder = true
