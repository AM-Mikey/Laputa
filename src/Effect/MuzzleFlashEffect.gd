extends Node2D

func _ready():
	$AnimationPlayer.play("MuzzleFlash")
	await $AnimationPlayer.animation_finished
	queue_free()
