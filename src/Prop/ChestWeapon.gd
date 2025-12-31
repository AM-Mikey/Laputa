extends PhysicsProp

var gun
var active_players = []

@export var gun_name: String
@export var used = false


func setup():
	gun = load("res://src/Gun/%s" % gun_name.to_pascal_case() + ".tscn").instantiate()
	inspect_time = 4.0 #got item interrupt length
	if used:
		$AnimationPlayer.play("used")

func _input(event):
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && p.can_input && p.mm.current_state == p.mm.states["run"]:
				if used:
					am.play("prop_deny")
					return
				var previous_look_dir = p.look_dir
				p.mm.change_state("inspect")
				p.look_dir = Vector2(sign(p.global_position.x - $CollisionShape2D.global_position.x), 0.0)
				activate(p)
				await get_tree().create_timer(inspect_time).timeout
				p.mm.change_state("run")
				p.look_dir = previous_look_dir


func activate(player):
	am.play("chest_open")
	am.play_interrupt("get_item")
	$AnimationPlayer.play("Used")
	used = true
	if gun:
		var already_has_gun = false
		for g in player.guns.get_children():
			if g.name == gun.name:
				already_has_gun = true
		if !already_has_gun:
			player.get_node("GunManager/Guns").add_child(gun)
			player.emit_signal("guns_updated", player.guns.get_children())
			print("added gun '", gun_name, "' to inventory")
		else:
			print("WARNING: Gun: ", gun_name, " already in inventory, ignoring")
	else:
		printerr("ERROR: INVALID GUN: ", gun_name)


#sparkle effects that descend, sparkle burst when opening

### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body):
	active_players.erase(body.get_parent())
