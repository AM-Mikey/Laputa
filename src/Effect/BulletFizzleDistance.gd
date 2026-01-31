extends Node2D

var direction = Vector2.RIGHT

func _ready():
	rotation = direction.angle()



func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()
