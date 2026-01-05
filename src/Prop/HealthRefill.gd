extends PhysicsProp

const HEART_GET_MAX = preload("res://src/Effect/HeartGetMax.tscn")

var active_players = []


func setup():
	inspect_time = 0.4

func _input(event):
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && p.can_input && p.mm.current_state == p.mm.states["run"]:
				if p.hp >= p.max_hp: #don't need it
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
	if player.hp < player.max_hp:
		player.hp = player.max_hp
		player.emit_signal("hp_updated", player.hp, player.max_hp, "refill_terminal")
		var heart_get_max = HEART_GET_MAX.instantiate()
		heart_get_max.global_position = $CollisionShape2D.global_position
		w.middle.add_child(heart_get_max)
		am.play("hp_refill")



#TODO: some particle effect when healing otherwise heal number, heartget escaping in 4 directions X pattern?

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body):
	active_players.erase(body.get_parent())
