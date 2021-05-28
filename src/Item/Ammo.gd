extends Area2D

var value: float

func _ready():
	if value <= 0.2:
		$AnimationPlayer.play("Small")
	else:
		$AnimationPlayer.play("Large")


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
