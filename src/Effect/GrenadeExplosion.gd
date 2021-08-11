extends Node2D

var size


func _ready():
	$AudioStreamPlayer2D.play()
	$AnimationPlayer.play(size)
	
	#yield($AnimationPlayer, "animation_finished")
	yield($AudioStreamPlayer2D, "finished")
	queue_free()
