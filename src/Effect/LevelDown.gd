extends Node2D

func _ready():
	$AnimationPlayer.play("LevelDown")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
