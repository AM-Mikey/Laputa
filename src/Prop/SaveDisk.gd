extends Prop

func activate():
	am.play("save")
	$AnimationPlayer.playback_speed = 0.5
	w.write_level_data_to_temp()
	w.write_player_data_to_save()
	w.copy_level_data_from_temp_to_save()
