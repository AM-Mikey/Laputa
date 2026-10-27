extends Node2D

func _ready():
	$AnimationPlayer.play("Land")
	oup.vibrate_impulse_light(0.1)
	await $AnimationPlayer.animation_finished
	queue_free()
