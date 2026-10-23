extends Node2D

func _ready() -> void:
	$AudioStreamPlayer2D.play()
	$AnimationPlayer.play("Small")

	await $AudioStreamPlayer2D.finished
	queue_free()
