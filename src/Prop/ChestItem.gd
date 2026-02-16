extends PhysicsProp

const GOT_ITEM = preload("res://src/UI/GotItem.tscn")

@export var held_item_name: String

var held_item: Item
var active_players = []


func setup(): #check if items are orphaned or not
	inspect_time = 4.0 #got item interrupt length
	held_item = load("res://src/Item/%s.tres" % held_item_name.to_pascal_case())
	if !held_item:
		expend_prop()


func _input(event):
	if !held_item: return
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
	var got_item = GOT_ITEM.instantiate()
	got_item.item_name = held_item_name
	w.ui.add_child(got_item)
	$AnimationPlayer.play("Used")
	spent = true

	if held_item:
		var already_has_item = false
		for i in player.item_array:
			if i == held_item:
				already_has_item = true
		if !already_has_item:
			player.item_array.append(held_item)
			mission_progress_check()
			print("added item: '", held_item_name, "' to item array")
		else:
			print("WARNING: Item: ", held_item_name, " already in item array, ignoring")
	else:
		printerr("ERROR: INVALID ITEM: ", held_item_name)


func expend_prop():
	spent = true
	$AnimationPlayer.play("Used")

func mission_progress_check(): #TODO: for main mission too
	for m in ms.side_missions:
		var stage: Array
		for s in m.stages:
			if s[0] == m.current_stage:
				stage = s
		if stage.size() == 3: #has trigger and value
			if stage[1] == "item":
				if stage[2].to_pascal_case() == held_item_name.to_pascal_case():
					ms.progress_side_mision(m.resource_path.get_file().trim_suffix(".tres"))


### SIGNALS ###

func _on_PlayerDetector_body_entered(body):
	active_players.append(body.get_parent())

func _on_PlayerDetector_body_exited(body):
	active_players.erase(body.get_parent())
