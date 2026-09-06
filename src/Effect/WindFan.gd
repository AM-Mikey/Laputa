extends Node2D

var direction := Vector2.RIGHT
var tile_distance := 21.0
var delay = 4.0
var is_stopping := false

const max_amount: = 500.0

func _ready():
	$Left.amount = max_amount
	$Right.amount = max_amount
	update()
	$Left.emitting = true
	await get_tree().create_timer(delay, false, true).timeout
	if !is_stopping:
		$Right.emitting = true


func update(): 
	if tile_distance <= 0.0:
		$Left.emitting = false
		$Right.emitting = false
	else:
		$Left.emitting = true
		$Right.emitting = true
		var lifetime = tile_distance / 6.5
		var amount = tile_distance * 1.5
		var visible_rect: = Rect2()
		visible_rect.size.x = (tile_distance + 16.0 * 3.0) * 7.0
		visible_rect.size.y = 16.0 * 3.0
		visible_rect.position.x = -16.0 * 1.5 * 7.0
		$Left.visibility_rect = visible_rect
		$Right.visibility_rect = visible_rect
		$Left.lifetime = lifetime
		$Right.lifetime = lifetime
		$Left.amount_ratio = amount / max_amount
		$Right.amount_ratio = amount / max_amount
		rotation = direction.angle()
	
func stop():
	is_stopping = true
	$Left.emitting = false
	$Right.emitting = false
	await get_tree().create_timer($Left.lifetime, false, true).timeout
	queue_free()
