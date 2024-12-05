extends Prop

func activate():
	expend_prop()
	active_pc.max_hp +=2
	active_pc.hp = active_pc.max_hp
	active_pc.emit_signal("hp_updated", active_pc.hp, active_pc.max_hp)
	am.play("hp_refill") #TODO: insert jingle
	print("got life capsule")

func expend_prop():
	spent = true
	$AnimationPlayer.play("Used")
