extends Node2D

func _ready():
	$AnimationPlayer.play("Bonk")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
