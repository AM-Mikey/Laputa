extends Node

var direction := Vector2.RIGHT
var tile_distance := 21.0

func _ready():
	var lifetime = tile_distance / 6.5
	$Left.lifetime = lifetime
	$Right.lifetime = lifetime
	$Left.direction = direction
	$Right.direction = direction
	$Left.emitting = true
	$Right.emitting = true
