extends PhysicsProp

const AMMO_GET = preload("res://src/Effect/AmmoGet.tscn")

var active_players = []

func _input(event):
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && p.can_input:
				activate(p)

func activate(player):
	var needed_ammo = false
	for g in player.guns.get_children():
		if g.ammo != g.max_ammo:
			g.ammo = g.max_ammo
			needed_ammo = true
	player.emit_signal("guns_updated", player.guns.get_children())
	if needed_ammo:
			am.play("ammo_refill") 
			var ammo_get = AMMO_GET.instantiate()
			ammo_get.global_position = global_position + Vector2(8.0, 10.0)
			w.front.add_child(ammo_get)
	else:
		am.play("prop_deny")



### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body):
	active_players.erase(body.get_parent())
