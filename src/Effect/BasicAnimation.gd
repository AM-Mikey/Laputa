extends Node2D

func _on_AnimationPlayer_animation_finished(_anim_name):
	print("ass")
	queue_free()
