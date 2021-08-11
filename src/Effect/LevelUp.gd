extends Node2D

func _ready():
	$AudioStreamPlayer2D.play()
	$AnimationPlayer.play("LevelUp")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
