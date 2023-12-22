extends Node2D

func _ready():
	$AnimationPlayer.play("LevelDown")
	await $AnimationPlayer.animation_finished
	queue_free()
