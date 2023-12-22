extends Node2D

var type: String
var normal: Vector2


func _ready():
	$Left.one_shot = true
	$Right.one_shot = true
	
	
	match type:
		"head": 
			am.play("pc_bonk")
			position.y -=16
		"feet": 
			am.play("pc_land")
	$Left.direction = normal.rotated(deg_to_rad(90))
	$Right.direction = normal.rotated(deg_to_rad(-90))


func _on_left_finished():
	queue_free()
