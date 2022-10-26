extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D



func _ready():
	match direction:
		Vector2.LEFT: rotation_degrees = 0
		Vector2.RIGHT: rotation_degrees = 180
		Vector2.UP: rotation_degrees = 90
		Vector2.DOWN: rotation_degrees = -90

func _physics_process(_delta):
	if disabled: return
	
	velocity = speed * direction
	velocity = move_and_slide(velocity)
	if origin.distance_to(global_position) > f_range:
		fizzle("range")
