extends Node2D

const BUBBLE = preload("res://src/Effect/Bubble.tscn")
@onready var w = get_tree().get_root().get_node("World")
var fully_submerged := false
var bubble_offset: Vector2

func _ready(): #only intended for enemy, but works on player for now
	var enemy_bounding_rect = get_parent().get_node("CollisionShape2D").shape.get_rect()
	var new_shape = RectangleShape2D.new()
	new_shape.size = Vector2(enemy_bounding_rect.size.x, 1)
	$CollisionShape2D.shape = new_shape
	$CollisionShape2D.position = get_parent().get_node("CollisionShape2D").position
	$CollisionShape2D.position.y -= (enemy_bounding_rect.size.y * 0.5) + 1 #should put this one above the enemy
	bubble_offset = Vector2(0, enemy_bounding_rect.size.y * -0.5)
	
func _on_timer_timeout():
	if fully_submerged:
		var bubble = BUBBLE.instantiate()
		bubble.global_position = global_position + bubble_offset
		w.front.add_child(bubble)


func _on_area_entered(area: Area2D):
	fully_submerged = true


func _on_area_exited(area: Area2D):
	fully_submerged = false
