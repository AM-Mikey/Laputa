extends Area2D

#var sfx_click = load("res://assets/SFX/Placeholder/snd_switchweapon.ogg")
export var style: int = 0

var has_player_near = false
var active_player = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.frame_coords.y = style

func _process(delta):
	yield(get_tree(), "idle_frame")
	$Sprite.frame_coords.x +=1
