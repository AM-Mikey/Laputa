extends Node2D

func _ready():
	$AnimationPlayer.play("Splash")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
