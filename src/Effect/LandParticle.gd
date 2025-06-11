extends Node2D

func _ready():
	am.play("pc_land")
	$AnimationPlayer.play("Land")
	await $AnimationPlayer.animation_finished
	queue_free()
