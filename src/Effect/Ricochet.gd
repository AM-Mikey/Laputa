extends Node2D

func _ready():
	$AnimationPlayer.play("Ricochet")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
