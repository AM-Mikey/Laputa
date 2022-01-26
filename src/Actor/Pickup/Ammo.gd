extends Area2D

var value: float

func _ready():
	match value:
		0.2: $AnimationPlayer.play("Small")
		0.5: $AnimationPlayer.play("Large")

func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
