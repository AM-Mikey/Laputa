extends Node2D

func _ready():
	am.play("explosion", self)
	$AnimationPlayer.play("Explosion")
	await $AnimationPlayer.animation_finished
	queue_free()
