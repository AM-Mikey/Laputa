extends Area2D

var value: int

#var velocity = Vector2(0, 10)

func _ready():
	if value <= 2:
		$AnimationPlayer.play("Small")
	else:
		$AnimationPlayer.play("Large")

#func _physics_process(delta):
#	move_and_slide(velocity, Vector2.UP)


func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
