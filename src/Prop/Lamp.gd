extends Prop

export var style: int = 0

func _ready():
	$Sprite.frame_coords.y = style

func activate():
	am.play("click")
	if $Sprite.frame_coords.x == 0:
		$Sprite.frame_coords.x = 1
		$Light2D.enabled = true
	elif $Sprite.frame_coords.x == 1:
		$Sprite.frame_coords.x = 0
		$Light2D.enabled = false
