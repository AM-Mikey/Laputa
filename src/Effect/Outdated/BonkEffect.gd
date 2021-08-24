extends Node2D

func _ready():
	$AudioStreamPlayer.play()
	$AnimationPlayer.play("Bonk")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
