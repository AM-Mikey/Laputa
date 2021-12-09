extends StaticBody2D

export var direction = Vector2.LEFT
export var speed = Vector2(60,60)

var active_pc = null

func _ready():
	constant_linear_velocity = speed * direction



func _on_PlayerDetector_body_entered(body):
	active_pc = body


func _on_PlayerDetector_body_exited(body):
	active_pc = null

func _physics_process(delta):
	if active_pc != null:
		active_pc.is_on_conveyor = active_pc.is_on_floor()
