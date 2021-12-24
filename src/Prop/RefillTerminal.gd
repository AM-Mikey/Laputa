extends Prop

var sfx_deny = load("res://assets/SFX/Placeholder/snd_quote_bonkhead.ogg")


func _on_body_entered(body):
	active_pc = body

func _on_body_exited(_body):
	active_pc = null

func _input(event):
	if event.is_action_pressed("inspect") and active_pc != null:
		if not active_pc.disabled:
			if active_pc.hp < active_pc.max_hp:
				active_pc.restore_hp()
			else:
				$SFX.stream = sfx_deny
				$SFX.play()
