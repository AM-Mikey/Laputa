extends Area2D

var active_player = null

func _on_Ladder_body_entered(body):
	active_player = body

func _on_Ladder_body_exited(_body):
	active_player.get_node("MovementManager").change_state(active_player.get_node("MovementManager").states["normal"])
	active_player = null


func _physics_process(delta):
	if active_player and not active_player.get_node("MovementManager").current_state == active_player.get_node("MovementManager").states["ladder"]:
		if Input.is_action_just_pressed("look_up") \
		or Input.is_action_just_pressed("look_down") and not active_player.is_on_floor() \
		or Input.is_action_just_pressed("look_down") and active_player.is_on_ssp:
			active_player.get_node("MovementManager").change_state(active_player.get_node("MovementManager").states["ladder"])
			active_player.position.x = position.x + 8
			active_player.position.y -= 1
