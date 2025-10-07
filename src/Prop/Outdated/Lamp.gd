extends Prop

@export var style: int = 0

func _ready():
	$Sprite2D.frame_coords.y = style

func activate():
	am.play("click")
	if $Sprite2D.frame_coords.x == 0:
		$Sprite2D.frame_coords.x = 1
		$PointLight2D.enabled = true
	elif $Sprite2D.frame_coords.x == 1:
		$Sprite2D.frame_coords.x = 0
		$PointLight2D.enabled = false
