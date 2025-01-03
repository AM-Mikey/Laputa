extends MarginContainer


func _on_boss_setup_ui(display_name, hp, max_hp):
	$Boss/HpProgress.value = hp
	$Boss/HpProgress.max_value = max_hp
	$Boss/HpLost.value = hp
	$Boss/HpLost.max_value = max_hp
	$Boss/BossName.text = display_name

func _on_boss_health_updated(hp):
	$Boss/HpProgress.value = hp
	#if hp < $Boss/HpLost.value:
		#$AnimationPlayer.play("Flash")
		#$AudioStreamPlayer.stream = _hurt
		#$AudioStreamPlayer.play()
	#elif hp > $HpBar/HpLost.value:
		#$AudioStreamPlayer.stream = _heal
		#$AudioStreamPlayer.play()
	var tween = get_tree().create_tween()
	tween.tween_property($Boss/HpLost, "value", hp, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(0.4)
