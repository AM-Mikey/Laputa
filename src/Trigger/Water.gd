extends Trigger

func _ready():
	trigger_type = "water"

func _on_Water_body_entered(body):
	active_bodies.append(body.get_parent())

	if not body.get_parent().is_in_water:
		body.get_parent().is_in_water = true
		
		var splash = load("res://src/Effect/Splash.tscn").instantiate()
		splash.position.x = body.global_position.x
		splash.position.y = global_position.y - 4
		get_tree().get_root().get_node("World/Front").add_child(splash)


func _on_Water_body_exited(body):
	if not get_overlap(body):
		body.is_in_water = false
	active_bodies.erase(body)
