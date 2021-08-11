extends Area2D


func _on_Water_body_entered(body):
	if not body.is_in_water:
		body.is_in_water = true
		var splash = load("res://src/Effect/Splash.tscn").instance()
		splash.position.x = body.global_position.x
		splash.position.y = global_position.y - 4
		get_tree().get_root().get_node("World/Front").add_child(splash)
		
