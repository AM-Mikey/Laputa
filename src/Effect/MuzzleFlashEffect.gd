extends Node2D

func _ready():
	$AnimationPlayer.play("MuzzleFlash")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
