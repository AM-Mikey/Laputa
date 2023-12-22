extends Node2D

func _ready():
	am.play("level_up")
	$AnimationPlayer.play("LevelUp")
	await $AnimationPlayer.animation_finished
	queue_free()
