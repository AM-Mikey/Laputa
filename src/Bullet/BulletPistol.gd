extends Bullet

var texture: StreamTexture
var texture_index: int
var collision_shape: RectangleShape2D

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var projectile_speed = Vector2.ZERO

var projectile_range: int

var origin = Vector2.ZERO


func _ready():
	if direction == Vector2.LEFT:
		rotation_degrees = 0
	if direction == Vector2.RIGHT:
		rotation_degrees = 180
	if direction == Vector2.UP:
		rotation_degrees = 90
	if direction == Vector2.DOWN:
		rotation_degrees = -90


func _physics_process(delta):
	
	velocity = projectile_speed * direction
	
	if disabled == false:
		move_and_slide(velocity)
		var distance_from_origin = origin.distance_to(global_position);
		if distance_from_origin > projectile_range:
			visible = false
			disabled = true
			_fizzle_from_range()
			


func _on_CollisionDetector_body_entered(body):
	if disabled == false:
		if body.get_collision_layer_bit(8): #breakable
					body.on_break("cut")
					if body.get_collision_layer_bit(3): #world
						visible = false
						disabled = true
						_fizzle_from_world()

		elif body.get_collision_layer_bit(1): #enemy
			var blood_direction = Vector2(floor((body.global_position.x - global_position.x)/10), floor((body.global_position.y - global_position.y)/10))
			body.hit(damage, blood_direction)
			queue_free()
		elif body.get_collision_layer_bit(3): #world
			visible = false
			disabled = true
			_fizzle_from_world()
