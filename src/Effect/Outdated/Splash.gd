extends Node2D

func _ready():
	$AnimationPlayer.play("Splash")
	await $AnimationPlayer.animation_finished
	queue_free()
