extends Trigger

func _ready():
	trigger_type = "water"

func _on_Water_body_entered(body):
	if body.get_collision_layer_bit(0): #player
		active_pc = body
	
	if body.get_collision_layer_bit(1): #enemy
		active_bodies.append(body)
	
	
	if not body.is_in_water:
		body.is_in_water = true
		
		var splash = load("res://src/Effect/Splash.tscn").instance()
		splash.position.x = body.global_position.x
		splash.position.y = global_position.y - 4
		get_tree().get_root().get_node("World/Front").add_child(splash)


func _on_Water_body_exited(body):
	if body.get_collision_layer_bit(0): #player
		if not get_overlap(body):
			active_pc.is_in_water = false
		active_pc = null


	if body.get_collision_layer_bit(1): #enemy
		if not get_overlap(body):
			body.is_in_water = false
		active_bodies.erase(body)
		
