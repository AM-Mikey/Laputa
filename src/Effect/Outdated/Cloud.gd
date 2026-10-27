extends CharacterBody2D

@export var speed = Vector2(200, 100)
@export var dir = Vector2.RIGHT
var safe_distance = 100

#onready var levels = get_tree().get_nodes_in_group("Levels")
#onready var cl = get_parent().get_parent().get_parent().get_node("CameraLimiter")
#
#
#func _physics_process(_delta):
#	if dir == Vector2.RIGHT:
#		if position.x >= cl.get_node("Right").position.x + safe_distance:
#			position.x = cl.get_node("Left").position.x - safe_distance
#
#	move_and_slide(speed * dir)
