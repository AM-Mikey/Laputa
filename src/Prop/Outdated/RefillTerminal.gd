extends Prop

func activate():
	if active_pc.hp < active_pc.max_hp:
		active_pc.hp = active_pc.max_hp
		active_pc.emit_signal("hp_updated", active_pc.hp, active_pc.max_hp, "refill_terminal")
		am.play("hp_refill")
	else:
		am.play("ui_deny")
