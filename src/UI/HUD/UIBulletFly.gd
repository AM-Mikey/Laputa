extends Sprite2D

var is_infinite := false

func _ready():
	if is_infinite:
		$AnimationPlayer.play("FlyInfinite")
	else:
		$AnimationPlayer.play("Fly")
	await $AnimationPlayer.animation_finished
	queue_free()
