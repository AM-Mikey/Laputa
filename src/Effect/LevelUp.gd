extends Node2D

func _ready():
	am.play("level_up")
	$AnimationPlayer.play("LevelUp")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
