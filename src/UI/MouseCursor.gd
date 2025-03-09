extends Node

var sf = 2.0
var current_cursor: String

var cursors = {
	"arrow" : [load("res://assets/UI/MouseCursor/Arrow.png"), Vector2i(0,0)],
	"brush" : [load("res://assets/UI/MouseCursor/Brush.png"), Vector2i(0,0)],
	"eraser" : [load("res://assets/UI/MouseCursor/Eraser.png"), Vector2i(0,0)],
	"grabclosed" : [load("res://assets/UI/MouseCursor/GrabClosed.png"), Vector2i(8,8)],
	"grabopen" : [load("res://assets/UI/MouseCursor/GrabOpen.png"), Vector2i(8,8)],
}


func _ready():
	display("arrow")

func display(string):
	current_cursor = string
	var texture = cursors[string][0]
	var hotspot = cursors[string][1] * sf
	Input.set_custom_mouse_cursor(scale_cursor(texture, sf), 0, hotspot)

func scale_cursor(texture, scale_factor) -> ImageTexture:
	var image = texture.get_image()
	image.resize(image.get_size().x * scale_factor, image.get_size().y * scale_factor, 0)
	var out = ImageTexture.create_from_image(image)
	return out
