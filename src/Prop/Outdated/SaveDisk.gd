extends Prop

func activate():
	am.play("save")
	$AnimationPlayer.speed_scale = 0.5
	SaveSystem.write_level_data_to_temp(w.current_level)
	SaveSystem.write_player_data_to_save(w.current_level)
	SaveSystem.copy_level_data_from_temp_to_save()
