extends Node2D
extends Path2D

@export var direction = "cw"
@export var speed = 1 #degrees per frame

var follower_path
var stop_condition

func _ready():
	var followers = $PathFollow2D.get_children()
	for f in followers:
		if f is Enemy:
			follower_path = $PathFollow2D.get_node(f.name)
			stop_condition = "dead"
	print(stop_condition)
	print(follower_path.get(stop_condition))

func _process(delta):
	$PathFollow2D.offset += speed
