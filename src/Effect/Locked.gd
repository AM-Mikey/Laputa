extends Node2D

func _ready():
	am.play("door_locked")
	oup.vibrate_impulse_light(0.1, 2.0)
	$AnimationPlayer.play("Locked")
	await $AnimationPlayer.animation_finished
	queue_free()
