extends Node2D

var direction = Vector2.UP

func _ready():
	$Left.direction = direction.rotated(-0.5 * PI)
	$Right.direction = direction.rotated(0.5 * PI)
	$Left.emitting = true
	$Right.emitting = true
	$Left.one_shot = true
	$Right.one_shot = true

func _on_Left_finished():
	queue_free()
