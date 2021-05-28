extends Area2D

var value: int

func _ready():
	if value <= 2:
		$AnimationPlayer.play("Small")
	else:
		$AnimationPlayer.play("Large")


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
