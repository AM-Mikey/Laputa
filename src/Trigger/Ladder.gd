extends Area2D

var active_player = null
var has_player_near = false

func _on_Ladder_body_entered(body):
	active_player = body
	has_player_near = true

func _on_Ladder_body_exited(body):
	active_player.is_on_ladder = false
	has_player_near = false

func _process(delta):
	if active_player != null and not active_player.is_on_ladder:
		if Input.is_action_just_pressed("look_up") and has_player_near \
		or Input.is_action_just_pressed("look_down") and has_player_near and not active_player.is_on_floor():
			active_player.is_on_ladder = true
			active_player.position.x = position.x +8
			active_player.position.y -= 1
