extends Node2D

func _ready():
	am.play("bullet_clink", self)

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
