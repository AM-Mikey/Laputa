extends Prop

func activate():
	var needed_ammo = false
	for g in active_pc.guns.get_children():
		if g.needs_ammo:
			if g.ammo != g.max_ammo:
				g.ammo = g.max_ammo
				needed_ammo = true
	active_pc.emit_signal("guns_updated", active_pc.guns.get_children())
	
	am.play("ammo_refill") if needed_ammo else am.play("ui_deny")
