extends Prop

export var style: int = 0

func _ready():
	$Sprite.frame_coords.y = style

func _process(delta):
	yield(get_tree(), "idle_frame")
	$Sprite.frame_coords.x +=1
