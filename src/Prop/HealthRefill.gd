extends PhysicsProp

const ICON = preload("res://assets/Prop/HealthRefillIcon.png")
const HEART_GET_MAX = preload("res://src/Effect/HeartGetMax.tscn")

var active_players = []



func setup(): #Reminder: no function called can use await
	inspect_time = 0.4
	w.emit_signal("finished_spawn_entities_step")

func player_interact(p: Player):
	if p.hp >= p.max_hp: #don't need it
		am.play("ui_deny")
	else:
		var previous_look_dir = p.look_dir
		p.mm.change_state("inspect")
		p.inspect_target = $CollisionShape2D
		activate(p)
		await get_tree().create_timer(inspect_time, false, true).timeout
		p.mm.change_state("run")
		p.look_dir = previous_look_dir


func activate(player: Player):
	if player.hp < player.max_hp:
		player.hp = player.max_hp
		player.emit_signal("hp_updated", player.hp, player.max_hp, "refill_terminal")
		var heart_get_max = HEART_GET_MAX.instantiate()
		heart_get_max.global_position = $CollisionShape2D.global_position
		w.farthest_front.add_child(heart_get_max)
		am.play("hp_refill")
		ms.mission_progress_check(id)
