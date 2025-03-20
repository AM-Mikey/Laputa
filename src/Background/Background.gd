@icon("res://assets/Icon/BackgroundIcon.png")
extends Resource
class_name Background

enum Focus {TOP, ONE_QUARTER, CENTER, THREE_QUARTERS, BOTTOM}
enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}

@export var texture: CompressedTexture2D
@export var layers := 1
@export var parallax_near := 1.0
@export var parallax_far := 0.0
@export var focus: Focus
@export var tile_mode: TileMode
