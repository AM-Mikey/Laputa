extends Trigger

var forbid = false

func _ready():
	trigger_type = "kill_box"
	w.emit_signal("finished_spawn_entities_step")
	visible = false

func _on_body_exited(body: Node2D):
	if forbid: return
	if body.get_collision_layer_value(1):
		var pc = body.get_parent()
		if !pc.die_from_falling || pc.mm.current_state == pc.mm.states["fly"]:
			return
		pc.die()
	elif body.get_collision_layer_value(2):
		print("killed ", body.name, " via killbox")
		body.die(true)
