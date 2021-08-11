extends Node2D

func _ready():
	$AnimationPlayer.play("StarPop")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
