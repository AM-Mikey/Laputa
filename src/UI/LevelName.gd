extends Control

func display_text(level_name):
	$AnimationPlayer.stop()
	$Label.text = level_name
	visible = true
	$AnimationPlayer.play("Fade")
	yield($AnimationPlayer, "animation_finished")
	visible = false
