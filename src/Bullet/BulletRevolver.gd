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
	velocity = speed * direction
	
	if not disabled:
		var _return_velo = move_and_slide(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > f_range:
			_fizzle_from_range()


func _on_CollisionDetector_body_entered(body):
	if not disabled:
		if body.get_collision_layer_bit(1): #enemy
			yield(get_tree(), "idle_frame")
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
			queue_free()
		elif body.get_collision_layer_bit(3): #world
			_fizzle_from_world()
