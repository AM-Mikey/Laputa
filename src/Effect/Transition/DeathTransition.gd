extends MarginContainer

@onready var w = get_tree().get_root().get_node("World")
@onready var pc = f.pc()

func _ready():
	$AnimationPlayer.play("IrisStarExpand")


func _process(_delta: float): #probably wasteful but keeps this perfect
	size = get_viewport_rect().size / vs.resolution_scale
	size += Vector2(8,8) #some safe distance
	global_position = get_viewport().get_camera_2d().get_target_position() - size * 0.5
