@icon("res://assets/Icon/BackgroundIcon.png")
extends Resource
class_name Background

enum Focus {TOP, ONE_QUARTER, CENTER, THREE_QUARTERS, BOTTOM}
enum TileMode {BOTH, HORIZONTAL, VERTICAL, NONE}
enum FarBackTileMode {DEFAULT, BOTH, HORIZONTAL, VERTICAL, NONE}

@export var texture: CompressedTexture2D
@export var layers := 1
@export var layer_scales : Dictionary
@export var focus: Focus
@export var tile_mode: TileMode
@export var far_back_tile_mode: FarBackTileMode
