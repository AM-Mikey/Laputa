extends Node2D

func _ready():
	$AnimationPlayer.play("Land")
	await $AnimationPlayer.animation_finished
	queue_free()
