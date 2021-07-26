extends Node2D

func _ready():
	$AnimationPlayer.play("Land")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
