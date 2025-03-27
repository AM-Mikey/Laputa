extends Node

var sf = 2.0
var current_cursor: String

var cursors = {
	"arrow" : [load("res://assets/UI/MouseCursor/Arrow.png"), Vector2i(0,0)],
	"brush" : [load("res://assets/UI/MouseCursor/Brush.png"), Vector2i(0,0)],
	"eraser" : [load("res://assets/UI/MouseCursor/Eraser.png"), Vector2i(0,0)],
	"grabclosed" : [load("res://assets/UI/MouseCursor/GrabClosed.png"), Vector2i(8,8)],
	"grabopen" : [load("res://assets/UI/MouseCursor/GrabOpen.png"), Vector2i(8,8)],
	"vsize" : [load("res://assets/UI/MouseCursor/VSize.png"), Vector2i(8,8)],
	"hsize" : [load("res://assets/UI/MouseCursor/HSize.png"), Vector2i(8,8)],
	"bdiagsize" : [load("res://assets/UI/MouseCursor/BDiagSize.png"), Vector2i(8,8)],
	"fdiagsize" : [load("res://assets/UI/MouseCursor/FDiagSize.png"), Vector2i(8,8)],
}


func _ready():
	display("arrow", Input.CURSOR_ARROW)
	display("vsize", Input.CURSOR_VSIZE)
	display("hsize", Input.CURSOR_HSIZE)
	display("bdiagsize", Input.CURSOR_BDIAGSIZE)
	display("fdiagsize", Input.CURSOR_FDIAGSIZE)

func display(string, shape = Input.CURSOR_ARROW):
	current_cursor = string
	var texture = cursors[string][0]
	var hotspot = cursors[string][1] * sf
	Input.set_custom_mouse_cursor(scale_cursor(texture, sf), shape, hotspot)

func scale_cursor(texture, scale_factor) -> ImageTexture:
	var image = texture.get_image()
	image.resize(image.get_size().x * scale_factor, image.get_size().y * scale_factor, 0)
	var out = ImageTexture.create_from_image(image)
	return out
