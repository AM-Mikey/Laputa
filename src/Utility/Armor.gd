extends StaticBody2D

## Expected to be replaced by a built-in mechanic in Godot 4.7 [br]
## Applicable only to RectangleShape, unrotated and in 4 main direction [br]
## Value of Vector2.ZERO mean block in every direction. Don't turn along with scale, rotation
@export var block_dir: Vector2 = Vector2.ZERO:
	set(val):
		for child in get_children():
			if child is CollisionShape2D and child.shape is RectangleShape2D:
				var curr_shape = collision_shape_size[child]
				if val != Vector2.ZERO:
					child.one_way_collision = true
					child.rotation = Vector2.DOWN.angle_to(-val)
				else:
					child.one_way_collision = false
					child.rotation = 0.0
				if val in [Vector2.LEFT, Vector2.RIGHT]:
					child.shape.size = curr_shape
				else:
					child.shape.size = curr_shape
		block_dir = val

## Assuming the shape rotation is 0.0
var collision_shape_size: Dictionary[Node, Vector2] = {}

signal blocked(body, shield_body)

func _ready() -> void:
	for child in get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			collision_shape_size[child] = child.shape.size
	block_dir = block_dir
