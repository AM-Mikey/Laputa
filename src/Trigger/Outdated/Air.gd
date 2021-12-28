extends Area2D

func _on_Air_body_entered(body):
	if body.is_in_water:
		body.is_in_water = false
#		if body.get_collision_layer_bit(0): #player
#			body.get_node("MovementManager").change_state(body.get_node("MovementManager").states["normal"])
