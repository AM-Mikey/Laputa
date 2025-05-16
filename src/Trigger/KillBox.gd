extends Trigger

func _ready():
	trigger_type = "kill_box"

func _on_body_entered(body): #note this currently only kills players and enemies
	print("killbox found body")
	if body.get_collision_layer_value(1): 
			var pc = body.get_parent()
			if !pc.die_from_falling or pc.mm.current_state == pc.mm.states["fly"]:
				return
			pc.die()
	elif body.get_collision_layer_value(2):
			print("killed ", body.name, " via killbox")
			body.die(true)
