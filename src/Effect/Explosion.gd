extends Node2D

func _ready():
	am.play("enemy_die", self)
	$AnimationPlayer.play("Explosion")
	await $AnimationPlayer.animation_finished
	queue_free()
