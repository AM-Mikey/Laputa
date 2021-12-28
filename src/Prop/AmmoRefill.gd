extends Prop

func activate():
	var needed_ammo = false
	for w in active_pc.weapon_array:
		if w.needs_ammo:
			if w.ammo != w.max_ammo:
				w.ammo = w.max_ammo
				needed_ammo = true
	active_pc.get_node("WeaponManager").update_weapon()
	
	am.play("ammo_refill") if needed_ammo else am.play("ui_deny")
