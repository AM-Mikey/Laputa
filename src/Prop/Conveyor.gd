extends StaticBody2D

export var direction = Vector2.LEFT
export var speed = Vector2(60,60)

func _ready():
	constant_linear_velocity = speed * direction
	#print(constant_linear_velocity, "clv")
