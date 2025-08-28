extends Prop

@export var style: int = 0

func _ready():
	$Sprite2D.frame_coords.y = style

func activate():
	am.play("click")
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("Spin")
