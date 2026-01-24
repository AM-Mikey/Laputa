extends PhysicsProp

var gun
var active_players = []

@export var gun_name: String


func setup():
	inspect_time = 4.0 #got item interrupt length
	var gun_scene = load("res://src/Gun/%s" % gun_name.to_pascal_case() + ".tscn")
	if gun_scene != null:
			gun = gun_scene.instantiate()
	else:
		printerr("ERROR: CAN'T FIND GUN WITH FILE PATH: res://src/Gun/%s" % gun_name.to_pascal_case() + ".tscn")


func expend_prop(): #used when loading a spent prop
	$AnimationPlayer.play("Used")


func _input(event):
	if !gun: return
	if event.is_action_pressed("inspect") && !active_players.is_empty():
		for p in active_players:
			if !p.disabled && p.can_input && p.mm.current_state == p.mm.states["run"]:
				if spent:
					am.play("prop_deny")
					return
				var previous_look_dir = p.look_dir
				p.mm.change_state("inspect")
				p.inspect_target = $CollisionShape2D
				activate(p)
				await get_tree().create_timer(inspect_time).timeout
				p.mm.change_state("run")
				p.look_dir = previous_look_dir


func activate(player):
	am.play("chest_open")
	am.play_interrupt("get_item")
	$AnimationPlayer.play("Used")
	spent = true
	if gun:
		var already_has_gun = false
		for g in player.guns.get_children():
			if g.name == gun.name:
				already_has_gun = true
		if !already_has_gun:
			player.get_node("GunManager/Guns").add_child(gun)
			player.get_node("GunManager/Guns").move_child(gun, 0)
			player.emit_signal("guns_updated", player.guns.get_children(), "get_gun")
			player.gm.set_guns_visible()
			print("added gun '", gun_name, "' to guns")
		else:
			print("WARNING: Gun: ", gun_name, " already in guns, ignoring")
	else:
		printerr("ERROR: INVALID GUN: ", gun_name)




#TODO: sparkle effects that descend, sparkle burst when opening



### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body):
	active_players.erase(body.get_parent())
