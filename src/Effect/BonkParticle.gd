extends Node2D

var normal: Vector2

var tx_land = load("res://assets/Effect/Land.png")

func _ready():
	$Left.one_shot = true
	$Right.one_shot = true
	am.play("pc_bonk")
	position.y -=16
	$Left.direction = normal.rotated(deg_to_rad(90))
	$Right.direction = normal.rotated(deg_to_rad(-90))


func _on_left_finished():
	queue_free()
