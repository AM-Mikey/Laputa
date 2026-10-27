extends Node2D

func _ready():
	am.play("bullet_thud", self)

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
