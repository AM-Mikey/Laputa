extends Node2D

func _ready():
	$AudioStreamPlayer2D.play()
	$AnimationPlayer.play("Explosion")
	#yield($AnimationPlayer, "animation_finished")
	yield($AudioStreamPlayer2D, "finished")
	queue_free()
