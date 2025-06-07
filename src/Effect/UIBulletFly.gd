extends Sprite2D

func _ready() -> void:
	$AnimationPlayer.play("Fly")
	await $AnimationPlayer.animation_finished
	queue_free()
