extends Prop

@export var style: int = 0

func _ready():
	$Sprite2D.frame_coords.y = style

func _process(delta):
	await get_tree().process_frame
	$Sprite2D.frame_coords.x +=1
