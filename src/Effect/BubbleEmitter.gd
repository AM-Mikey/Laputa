extends Node2D

const BUBBLE = preload("res://src/Effect/Bubble.tscn")
@onready var w = get_tree().get_root().get_node("World")

func _on_timer_timeout() -> void:
	var bubble = BUBBLE.instantiate()
	bubble.global_position = global_position
	w.front.add_child(bubble)
