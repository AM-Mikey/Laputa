extends Node

var direction := Vector2.RIGHT
var tile_distance := 21.0
var delay = 4.0
var is_stopping := false

func _ready():
	var lifetime = tile_distance / 6.5
	var amount = tile_distance * 1.5
	$Left.lifetime = lifetime
	$Right.lifetime = lifetime
	$Left.amount = amount
	$Right.amount = amount
	$Left.direction = direction
	$Right.direction = direction
	$Left.emitting = true
	await get_tree().create_timer(delay, false, true).timeout
	if !is_stopping:
		$Right.emitting = true

func stop():
	is_stopping = true
	$Left.emitting = false
	$Right.emitting = false
	await get_tree().create_timer($Left.lifetime, false, true).timeout
	queue_free()
