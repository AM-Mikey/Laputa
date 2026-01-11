extends PhysicsProp

const AMMO_GET_MAX = preload("res://src/Effect/AmmoGetMax.tscn")

var active_players = []


func setup():
	inspect_time = 0.4

func _input(event):
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && p.can_input && p.mm.current_state == p.mm.states["run"]:
				if !get_is_ammo_needed(p):
					am.play("ui_deny")
				else:
					var previous_look_dir = p.look_dir
					p.mm.change_state("inspect")
					p.inspect_target = $CollisionShape2D
					activate(p)
					await get_tree().create_timer(inspect_time).timeout
					p.mm.change_state("run")
					p.look_dir = previous_look_dir


func activate(player):
	for g in player.guns.get_children():
		if g.ammo != g.max_ammo:
			g.ammo = g.max_ammo
	player.emit_signal("guns_updated", player.guns.get_children())
	var ammo_get_max = AMMO_GET_MAX.instantiate()
	ammo_get_max.global_position = $CollisionShape2D.global_position
	w.middle.add_child(ammo_get_max)
	am.play("ammo_refill")


func get_is_ammo_needed(player) -> bool:
	var out = false
	for g in player.guns.get_children():
		if g.ammo != g.max_ammo:
			out = true
	return out

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body):
	active_players.erase(body.get_parent())
