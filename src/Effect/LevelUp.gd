extends Node2D

func _ready():
	am.play("level_up")
	oup.vibrate_impulse_light(0.4, 2.0)
	$AnimationPlayer.play("LevelUp")
	await $AnimationPlayer.animation_finished
	queue_free()
