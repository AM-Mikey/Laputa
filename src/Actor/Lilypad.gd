extends CharacterBody2D

var pcs_on_top = []
var enemies_on_top = []
var speed = 4
#var acceleration = 0.2

@export var sprite = 0
@export var stop_distance = 16

@onready var starting_pos = global_position
@onready var min_pos = global_position + Vector2(0, stop_distance)

func _ready():
	$Sprite2D.frame = sprite

func _physics_process(_delta):
	if pcs_on_top.is_empty() and enemies_on_top.is_empty():
		if abs(global_position.y - starting_pos.y) < 0.1:
			global_position = starting_pos
			return
		var direction = starting_pos - global_position
		velocity = direction * speed
		move_and_slide()
	else:
		if abs(global_position.y - min_pos.y) < 0.1:
			global_position = min_pos
			return
		velocity = Vector2.DOWN * speed
		move_and_slide()

func _on_CbDetector_body_entered(body: Node2D):
	if body.get_collision_layer_value(1): #player
		pcs_on_top.append(body.get_parent())
	if body.get_collision_layer_value(2): #enemy
		enemies_on_top.append(body)

func _on_CbDetector_body_exited(body: Node2D):
	if body.get_collision_layer_value(1): #player
		if pcs_on_top.has(body.get_parent()):
			pcs_on_top.erase(body.get_parent())
	if body.get_collision_layer_value(2): #enemy
		if enemies_on_top.has(body):
			enemies_on_top.erase(body)
