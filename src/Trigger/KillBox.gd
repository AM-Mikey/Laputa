extends Trigger

var forbid = false

func setup():
	trigger_type = "kill_box"
	visible = false
	w.emit_signal("finished_spawn_entities_step")

func _on_body_entered(body: Node2D):
	if forbid: return
	if body.get_collision_layer_value(1): #player
		var pc = body.get_parent()
		if pc.dead: return
		if !pc.die_from_falling: return
		if pc.mm.current_state == pc.mm.states["fly"]: return
		if pc.load_zones_inside.size() != 0: return
		pc.die(true)
	elif body.get_collision_layer_value(2): #enemy
		print("killed ", body.name, " via killbox")
		body.die(true)
