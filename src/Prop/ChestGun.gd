extends PhysicsProp

const ICON = preload("res://assets/Prop/ChestGunIcon.png")
const GOT_GUN = preload("res://src/UI/GotGun.tscn")

var gun

@export var gun_name: String


func setup(): #Reminder: no function called can use await
	inspect_time = 4.0 #got item interrupt length
	var gun_scene = load("res://src/Gun/%s" % gun_name.to_pascal_case() + ".tscn")
	if gun_scene != null:
			gun = gun_scene.instantiate()
	else:
		printerr("ERROR: CAN'T FIND GUN WITH FILE PATH: res://src/Gun/%s" % gun_name.to_pascal_case() + ".tscn")
	w.emit_signal("finished_spawn_entities_step")

func expend_prop(): #used when loading a spent prop
	$AnimationPlayer.play("Used")

func player_interact(p: Player):
	if !gun: return
	if spent:
		am.play("prop_deny")
		return
	var previous_look_dir = p.look_dir
	p.mm.change_state("inspect")
	p.inspect_target = $CollisionShape2D
	activate(p)
	await get_tree().create_timer(inspect_time, false, true).timeout
	p.mm.change_state("run")
	p.look_dir = previous_look_dir


func activate(player: Player):
	am.play("chest_open")
	am.play_interrupt("get_item")
	var got_gun = GOT_GUN.instantiate()
	got_gun.gun_name = gun.display_name
	w.ui.add_child(got_gun)
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
			ms.mission_progress_check()
			print("added gun '", gun_name, "' to guns")
		else:
			print("WARNING: Gun: ", gun_name, " already in guns, ignoring")
	else:
		printerr("ERROR: INVALID GUN: ", gun_name)




#TODO: sparkle effects that descend, sparkle burst when opening
